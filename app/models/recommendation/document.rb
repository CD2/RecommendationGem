module Recommendation
  class Document < ::Recommendation::ApplicationRecord
    belongs_to :recommendable, polymorphic: true, inverse_of: :recommendation_document

    before_save :update_tags_cache
    before_save :remove_zero_tags

    def self.all_tags
      pluck('DISTINCT jsonb_object_keys(tags_cache)')
    end

    def self.tagged_with tag_name
      query_chain do
        expand_json(:tags_cache)
        where('value::numeric > 0 AND key = ?', @self.normalize(tag_name))
        group(:id)
      end
    end

    def cache_change(tag, change)
      tags_cache[tag] = (tags_cache[tag] || 0) + change
    end

    def remove_zero_tags
      static_tags.reject! { |k, v| v == 0 }
      tags_cache.reject! { |k, v| v == 0 }
    end

    def update_tags_cache
      return recalculate_tags if new_record?
      if static_tags_changed?
        (static_tags_was.keys | static_tags.keys).each do |tag|
          cache_change tag, (static_tags[tag] || 0) - (static_tags_was[tag] || 0)
        end
      end
    end

    def recalculate_tags
      dynamic_tags = {}
      result = query_chain(Document) {
        expand_json(:tags_cache)
        inner_join Vote, on: {
          recommendable_id: :votable_id,
          recommendable_type: :votable_type
        }
        where('voter_id = ?', recommendable_id)
        where('voter_type = ?', recommendable_type)
        group(:tag)
        select('json.key AS tag')
        select("SUM(json.value::numeric * #{Vote.weight}) AS weight")
      }
      result.raw.each { |x| dynamic_tags[x['tag']] = x['weight'].to_f }
      self.tags_cache = static_tags.merge(dynamic_tags) { |k, v1, v2| v1 + v2 }
    end

    def increment vote
      vote.votable.tags_hash.each do |tag, weight|
        cache_change tag, vote.weight * weight
      end
      save!
    end

    def decrement vote
      vote.votable.tags_hash.each do |tag, weight|
        cache_change tag, -1 * vote.weight * weight
      end
      save!
    end

    def invert vote
      vote.votable.tags_hash.each do |tag, weight|
        cache_change tag, 2 * vote.weight * weight
      end
      save!
    end

    def self.r_score_formula
      'coalesce((SUM(subject_doc.value * model_docs.value)), 0)'
    end

    def self.recommend relation, subject
      qlass = relation.klass

      subject_doc = query_chain do
        where(recommendable: subject)
        expand_json(:tags_cache)
        select('key', 'value::numeric')
        to_sql
      end

      model_docs = query_chain do
        where(recommendable_type: qlass.name)
        expand_json(:tags_cache)
        select(:recommendable_id, 'key', 'value::numeric')
      end

      scores = query_chain do
        from("(#{subject_doc}) AS subject_doc")
        right_join(model_docs,
          as: :model_docs,
          on: ['subject_doc.key = model_docs.key']
        )
        group(:recommendable_id)
        select(:recommendable_id)
        select("#{@self.r_score_formula} AS recommendation_score")
        to_sql
      end

      relation = relation.where.not(id: subject.id) if subject.is_a?(qlass)

      relation
      .joins("LEFT JOIN (#{scores}) AS recommendation ON recommendable_id = id")
      .order('coalesce(recommendation_score, 0) DESC')
    end
  end
end

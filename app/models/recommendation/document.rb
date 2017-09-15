# frozen_string_literal: true

module Recommendation
  class Document < ::Recommendation::ApplicationRecord
    belongs_to :recommendable, polymorphic: true, inverse_of: :recommendation_document

    before_save :update_tags_cache
    before_save :remove_zero_tags

    def self.all_tags
      pluck('DISTINCT jsonb_object_keys(tags_cache)')
    end

    def self.tagged_with(*tag_names)
      options = tag_names.extract_options!
      options.assert_valid_keys(:allow_negative)
      allow_negative = options.fetch(:allow_negative, false)

      tag_names.map! { |x| normalize(x) }
      query_chain do
        expand_json(:tags_cache)
        where('key IN (?)', tag_names)
        where('value::numeric > 0') unless allow_negative
        group(:id)
        having('COUNT(key) = ?', tag_names.count)
      end
    end

    def cache_change(tag, change)
      tags_cache[tag] = (tags_cache[tag] || 0) + change
    end

    def remove_zero_tags
      static_tags.reject! { |_k, v| v == 0 }
      tags_cache.reject! { |_k, v| v == 0 }
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
      result = query_chain(Document) do
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
      end
      result.raw.each { |x| dynamic_tags[x['tag']] = x['weight'].to_f }
      self.tags_cache = static_tags.merge(dynamic_tags) { |_k, v1, v2| v1 + v2 }
    end

    def increment(vote)
      vote.votable.tags_hash.each do |tag, weight|
        cache_change tag, vote.weight * weight
      end
      save!
    end

    def decrement(vote)
      vote.votable.tags_hash.each do |tag, weight|
        cache_change tag, -1 * vote.weight * weight
      end
      save!
    end

    def invert(vote)
      vote.votable.tags_hash.each do |tag, weight|
        cache_change tag, 2 * vote.weight * weight
      end
      save!
    end

    def self.tag_match_formula
      'coalesce((SUM(subject_doc.value * model_docs.value)), 0)'
    end

    def self.by_tags(relation, subject)
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

      query_chain do
        from("(#{subject_doc}) AS subject_doc")
        right_join(model_docs,
                   as: :model_docs,
                   on: ['subject_doc.key = model_docs.key'])
        group(:recommendable_id)
        select(:recommendable_id)
        select("#{@self.tag_match_formula} AS score")
        to_sql
      end
    end

    def self.by_distance(relation, subject)
      qlass = relation.klass

      query_chain do
        where(recommendable_type: qlass.name)
        select(:recommendable_id)
        if subject.lat && subject.lng
          select("point(lng, lat) <@> point(#{subject.lng}, #{subject.lat}) AS distance")
        else
          select('NULL::float AS distance')
        end
        to_sql
      end
    end

    def self.by_time(relation)
      age = 'GREATEST(EXTRACT(epoch FROM current_timestamp - created_at), 2)'
      zero_age = 20.years.seconds
      scaled_age = "((#{age} * 9) / #{zero_age}) + 1"
      score = "1 - log(#{scaled_age})"
      min_score = 0.5
      score = "GREATEST(#{score}, #{min_score})"

      # y = 1 - log(9x + 1) (above)
      # y = 1 + log(1 - 9x/10) (not yet implemented)

      relation.select(:id).select("#{score} AS score").to_sql
    end
  end
end

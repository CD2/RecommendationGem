# frozen_string_literal: true

module Recommendation
  module Cache
    extend ActiveSupport::Concern

    included do
      before_save :update_tags_cache
      before_save :remove_zero_tags

      def cache_change(tag, change)
        tags_cache[tag] = (tags_cache[tag] || 0.0) + change
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
        self.tags_cache = static_tags.merge(dynamic_tags) { |_k, v1, v2| v1 + v2 }
      end

      def dynamic_tags
        result = {}

        tag_records = query_chain(::Recommendation::Document) do
          expand_json(:tags_cache)
          inner_join ::Recommendation::Vote, on: {
            recommendable_id: :votable_id,
            recommendable_type: :votable_type
          }
          where('voter_id = ?', recommendable_id)
          where('voter_type = ?', recommendable_type)
          group(:tag)
          select('json.key AS tag')
          select("SUM(json.value::numeric * recommendation_votes.weight) AS weight")
        end

        model_records = query_chain(::Recommendation::Vote) do
          where(voter_type: recommendable_type, voter_id: recommendable_id)
          group(:votable_type)
          select("'$model:' || votable_type AS tag")
          select('SUM(recommendation_votes.weight) AS weight')
        end

        records = tag_records.raw + model_records.raw
        records.each { |x| result[x['tag']] = x['weight'].to_f }
        result
      end

      def increment(vote)
        cache_change compose_model_tag(vote.votable_type), vote.weight
        vote.votable.tags_hash.each do |tag, weight|
          cache_change tag, vote.weight * weight
        end
        save!
      end

      def decrement(vote)
        cache_change compose_model_tag(vote.votable_type), -1 * vote.weight
        vote.votable.tags_hash.each do |tag, weight|
          cache_change tag, -1 * vote.weight * weight
        end
        save!
      end

      def invert(vote)
        cache_change compose_model_tag(vote.votable_type), 2 * vote.weight
        vote.votable.tags_hash.each do |tag, weight|
          cache_change tag, 2 * vote.weight * weight
        end
        save!
      end
    end
  end
end

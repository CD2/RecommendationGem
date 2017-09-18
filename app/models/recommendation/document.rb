# frozen_string_literal: true

module Recommendation
  class Document < ::Recommendation::ApplicationRecord
    include ::Recommendation::Cache
    include ::Recommendation::Metrics::Composite
    include ::Recommendation::Metrics::Distance
    include ::Recommendation::Metrics::Popularity
    include ::Recommendation::Metrics::Tags
    include ::Recommendation::Metrics::Time

    belongs_to :recommendable, polymorphic: true, inverse_of: :recommendation_document

    def self.all_tags
      pluck('DISTINCT jsonb_object_keys(tags_cache)')
    end

    def self.tagged_with(tag_names, allow_negative = false)
      tag_names.map! { |x| normalize(x) }
      query_chain do
        expand_json(:tags_cache)
        where('key IN (?)', tag_names)
        where('value::numeric > 0') unless allow_negative
        group(:id)
        having('COUNT(key) = ?', tag_names.count)
      end
    end
  end
end

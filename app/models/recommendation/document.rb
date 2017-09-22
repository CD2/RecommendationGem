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

    delegate :parse_special_tag, :compose_special_tag, :method_missing,
             :remove_special_tags, :only_special_tags, to: :class

    def self.parse_special_tag special_tag
      result = special_tag.to_s.scan /(?<=\A\$)[^:]+|(?<=:).+/
      result = nil unless result.size == 2
      result
    end

    def self.compose_special_tag special, tag
      "$#{special}:#{tag}"
    end

    def self.remove_special_tags h
      h.reject { |k, _v| parse_special_tag(k) }.to_h
    end

    def self.only_special_tags h
      h.select { |k, _v| parse_special_tag(k) }.to_h
    end

    def self.method_missing name, *args, &block
      if special_tag_type = name.to_s.match(/(?<=\Acompose_).+(?=_tag\z)/)&.to_s
        compose_special_tag(special_tag_type, *args, &block)
      else
        super
      end
    end
  end
end

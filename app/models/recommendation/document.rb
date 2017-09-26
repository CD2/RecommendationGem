# frozen_string_literal: true

module Recommendation
  class Document < ::Recommendation::RecommendationRecord
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

    def self.tagged_with(tag_names, allow_negative = false, any = false)
      tag_names.map! { |x| normalize(x) }
      query_chain do
        expand_json(:tags_cache)
        where('key IN (?)', tag_names)
        where('value::numeric > 0') unless allow_negative
        group(:id)
        if any
          having('COUNT(key) > 0')
        else
          having('COUNT(key) = ?', tag_names.count)
        end
      end
    end

    def self.merge_tags(tag_names, new_name)
      tag_names.map! { |x| normalize(x) }
      new_name = normalize(new_name)

      cache_score = tag_names.map { |x|
        "coalesce((tags_cache ->> '#{x}')::numeric, 0)"
      }.join(' + ')
      cache_entry = "jsonb_build_object('#{new_name}', #{cache_score})"

      static_score = tag_names.map { |x|
        "coalesce((static_tags ->> '#{x}')::numeric, 0)"
      }.join(' + ')
      static_entry = "jsonb_build_object('#{new_name}', #{static_score})"

      remove_keys = tag_names.map { |x| "- '#{x}'" }.join(' ')

      sql_execute %{
        UPDATE recommendation_documents
        SET
          tags_cache = tags_cache #{remove_keys} || #{cache_entry},
          static_tags = static_tags #{remove_keys} || #{static_entry}
        WHERE
          id IN (#{tagged_with(tag_names, true, true).select(:id).as_sql})
      }
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

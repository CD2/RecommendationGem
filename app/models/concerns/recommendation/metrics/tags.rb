# frozen_string_literal: true

module Recommendation
  module Metrics
    module Tags
      extend ActiveSupport::Concern

      included do
        def self.tags_metric(relation, subject, _weights = nil)
          min_value = 0.1

          qlass = relation.klass

          s_doc = query_chain do
            where(recommendable: subject)
            expand_json(:tags_cache)
            select('key', 'value::numeric')
            as_sql
          end

          model_docs = query_chain do
            where(recommendable_type: qlass.name)
            expand_json(:tags_cache)
            select(:recommendable_id, 'key', 'value::numeric')
          end

          tag_value = 'coalesce((SUM(s_doc.value * model_docs.value)), 0)'

          tag_values = query_chain do
            from("(#{s_doc}) AS s_doc")
            right_join(model_docs,
                       as: :model_docs,
                       on: ['s_doc.key = model_docs.key'])
            group(:recommendable_id)
            select(:recommendable_id)
            select('array_remove(array_agg(s_doc.key), NULL) AS tags')
            select("#{tag_value} AS tag_value")
          end

          max_tag_value = Q::Metric.new('MAX(tag_value) OVER ()').at_least(1)
          score = Q::Metric.new("tag_value / #{max_tag_value}").at_least(min_value)

          query_chain do
            from("(#{tag_values.as_sql}) AS tag_values")
            select('recommendable_id AS id')
            select("coalesce(#{score}, #{min_value}) AS score")
            select("coalesce(tags, '{}') AS value")
            as_sql
          end
        end
      end
    end
  end
end

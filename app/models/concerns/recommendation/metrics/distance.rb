# frozen_string_literal: true

module Recommendation
  module Metrics
    module Distance
      extend ActiveSupport::Concern

      included do
        def self.distance_metric(relation, subject, _weights = nil)
          min_value = 0.1

          qlass = relation.klass
          s_doc = subject.recommendation_document

          distance = "point(lng, lat) <@> point(#{s_doc.lng}, #{s_doc.lat})"
          score = Q::Metric.new(distance).linear_decline(500).at_least(min_value)

          query_chain do
            where(recommendable_type: qlass.name)
            select('recommendable_id AS id')
            if s_doc.lat && s_doc.lng
              select("coalesce(#{score}, #{min_value}) AS score")
              select("#{distance} AS value")
            else
              select('1 AS score')
              select('NULL::float AS value')
            end
            as_sql
          end
        end
      end
    end
  end
end

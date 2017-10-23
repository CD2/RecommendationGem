# frozen_string_literal: true

module Recommendation
  module Metrics
    module Composite
      extend ActiveSupport::Concern

      included do
        def self.composite_metric(relation, subject, weights)
          qlass = relation.klass

          result = where(recommendable_type: qlass.name)
          scores = []

          weights.each do |m, w|
            metric_name = "#{m}_metric"
            sub_query = send(metric_name, relation, subject)
            result = result.left_join(sub_query,
                                      as: metric_name,
                                      on: { recommendable_id: :id })
            scores << "(#{Q.quote(metric_name, :score)} * #{w})"
            result = result.select("#{m}_metric.score AS #{m}_score")
            result = result.select("#{m}_metric.value AS #{m}_value")
          end

          max = weights.values.max
          max = 1 if max.nil? || max.zero?
          score = "(#{scores.join(' + ')}) / #{max * weights.count}"

          score = '1' unless weights.any?

          result.select('recommendable_id AS id', "#{score} AS score").as_sql
        end
      end
    end
  end
end

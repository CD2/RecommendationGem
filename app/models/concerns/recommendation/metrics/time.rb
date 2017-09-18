# frozen_string_literal: true

module Recommendation
  module Metrics
    module Time
      extend ActiveSupport::Concern

      included do
        def self.time_metric(relation, _subject = nil, _weights = nil)
          min_value = 0.5

          age = 'GREATEST(EXTRACT(epoch FROM current_timestamp - created_at), 2)'
          score = Q::Metric.new(age).curve_decline(20.years.seconds).at_least(min_value)

          str = relation
                .select(:id)
                .select("coalesce(#{score}, #{min_value}) AS score")
                .select('created_at AS value')
                .to_sql

          Q::SQLString.new(str)
        end
      end
    end
  end
end

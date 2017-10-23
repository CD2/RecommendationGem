# frozen_string_literal: true

module Recommendation
  module Metrics
    module Popularity
      extend ActiveSupport::Concern

      included do
        def self.popularity_metric(relation, _subject = nil, _weights = nil)
          min_value = 0.1

          qlass = relation.klass

          vote_sum = 'SUM(weight)'
          max_vote_sum = "MAX(abs(#{vote_sum})) OVER ()"
          max_vote_sum = ::Recommendation::Q::Metric.new(max_vote_sum).at_least(1)
          score = ::Recommendation::Q::Metric.new("#{vote_sum} / #{max_vote_sum}").at_least(min_value)

          model_docs = ::Recommendation::Document.where(recommendable_type: qlass)

          ::Recommendation::Vote.query_chain do
            right_join(model_docs, on: [
              [:votable_id, :recommendable_id],
              "votable_type = '#{qlass}' OR votable_type IS NULL"
            ])
            where(votable_type: [qlass, nil])
            group(:recommendable_id)
            select('recommendable_id AS id')
            select("coalesce(#{score}, #{min_value}) AS score")
            select("coalesce(#{vote_sum}, 0) AS value")
            as_sql
          end
        end
      end
    end
  end
end

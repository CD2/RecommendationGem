# frozen_string_literal: true

module Recommendation
  module Recommendable
    module Metrics
      extend ActiveSupport::Concern

      included do
        def self.recommend_to(subject, opts = {})
          options = opts.to_options
          influences = Array.wrap(options.fetch(:based_on, :tags))
          options.delete(:based_on)
          influences_hash = influences.extract_options!.reject{ |_k, v| v == 0 }
          influences.each { |x| influences_hash[x] ||= 1 }

          by_metric(:composite, subject, options, influences_hash)
        end

        class << self
          %w[distance tags].each do |metric|
            define_method "by_#{metric}".to_sym do |subject, opts = {}|
              by_metric(metric, subject, opts, nil)
            end
          end

          %w[popularity time].each do |metric|
            define_method "by_#{metric}".to_sym do |opts = {}|
              by_metric(metric, nil, opts, nil)
            end
          end
        end

        private

        def self.by_metric(metric, subject, opts, weights)
          options = opts.to_options
          options.assert_valid_keys(:exclude_self, :include_score, :include_value, :order)
          exclude_self = options.fetch(:exclude_self, true)
          include_score = options.fetch(:include_score, false)
          include_value = options.fetch(:include_value, false)
          order_results = options.fetch(:order, true)

          scores = ::Recommendation::Document.send("#{metric}_metric", all, subject, weights)

          result = all

          if include_score
            result = result.select(::Recommendation::Q.quote(table_name, :*)) if result.select_values.empty?
            result = result.select("#{metric}_metric.score AS #{metric}_score")
            if metric.to_s == 'composite'
              weights.each { |k, _v| result = result.select("#{k}_score") }
            end
          end

          if include_value
            result = result.select(::Recommendation::Q.quote(table_name, :*)) if result.select_values.empty?
            if metric.to_s == 'composite'
              weights.each { |k, _v| result = result.select("#{k}_value") }
            else
              result = result.select("#{metric}_metric.value AS #{metric}_value")
            end
          end

          result = result.order("#{metric}_metric.score DESC") if order_results

          result.joins("LEFT JOIN (#{scores}) AS #{metric}_metric ON #{metric}_metric.id = #{table_name}.id")
        end
      end
    end
  end
end

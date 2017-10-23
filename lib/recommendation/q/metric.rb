# frozen_string_literal: true

require_dependency "#{File.dirname(__FILE__)}/core.rb"

module Recommendation
  module Q
    class Metric
      def initialize(value)
        @value = Q.bracket(value)
      end

      def linear_decline(intersect)
        Metric.new("1 - (#{@value} / #{intersect})")
      end

      def curve_decline(intersect)
        Metric.new("1 - log(((#{@value} * 9) / #{intersect}) + 1)")
      end

      def at_least(minimum)
        Metric.new("GREATEST(#{@value}, #{minimum})")
      end

      def to_sql
        @value
      end

      alias to_s to_sql
      alias inspect to_sql
    end
  end
end

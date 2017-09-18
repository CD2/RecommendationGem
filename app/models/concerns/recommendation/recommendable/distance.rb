# frozen_string_literal: true

module Recommendation
  module Recommendable
    module Distance
      extend ActiveSupport::Concern

      included do
        def self.within_distance(subject, distance)
          return none unless subject.has_coordinates?
          str = "point(lat, lng) <@> point(#{subject.coordinates.join(', ')})"
          docs = ::Recommendation::Document.query_chain do
            where(recommendable_type: @self.name)
            where("(#{str}) <= ?", distance)
            select(:recommendable_id)
          end
          where(id: docs)
        end
      end

      def distance_to(subject)
        return nil unless has_coordinates? && subject.has_coordinates?
        points = [
          "point(#{coordinates.join(', ')})",
          "point(#{subject.coordinates.join(', ')})"
        ]
        ::Recommendation::Document.sql_calculate(
          "SELECT #{points[0]} <@> #{points[1]}"
        )
      end

      def has_coordinates?
        !!(recommendation_document.lat && recommendation_document.lng)
      end

      def coordinates
        [recommendation_document.lat, recommendation_document.lng]
      end
    end
  end
end

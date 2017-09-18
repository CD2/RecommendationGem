# frozen_string_literal: true

module Recommendation
  module Recommendable
    module Core
      extend ActiveSupport::Concern

      included do
        has_one :recommendation_document, {
          as: :recommendable,
          inverse_of: :recommendable,
          class_name: '::Recommendation::Document'
        }

        after_create :recommendation_document
      end

      def recommendation_document
        super || create_recommendation_document!
      end

      def recommendation_score
        attributes['composite_score']
      end

      def popularity_value(force = false)
        !force && attributes['popularity_value'] || votes_as_votable.sum(:weight)
      end
    end
  end
end

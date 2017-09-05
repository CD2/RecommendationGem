class RecommendationDocument < ApplicationRecord
  belongs_to :recommendable, polymorphic: true, inverse_of: :recommendation_document
end

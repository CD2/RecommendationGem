# frozen_string_literal: true

module Recommendation
  class Vote < ::Recommendation::RecommendationRecord
    belongs_to :voter, polymorphic: true, inverse_of: :votes_as_voter
    belongs_to :votable, polymorphic: true, inverse_of: :votes_as_votable

    validates :weight, inclusion: { in: [-1, 1] }
    validates :voter_id, uniqueness: { scope: %i[voter_type votable_id votable_type] }

    scope :up, -> { where(weight: 1) }
    scope :down, -> { where(weight: -1) }

    after_save :update_tags_cache
    after_destroy :update_tags_cache

    def voter_document
      ::Recommendation::Document.find_or_initialize_by(recommendable_id: voter_id, recommendable_type: voter_type)
    end

    def update_tags_cache
      if destroyed?
        voter_document.decrement(self)
      elsif saved_change_to_id?
        voter_document.increment(self)
      elsif saved_change_to_weight?
        voter_document.invert(self)
      end
    end
  end
end

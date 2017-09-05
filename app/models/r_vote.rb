class RVote < ApplicationRecord
  belongs_to :voter, polymorphic: true, inverse_of: :r_votes_as_voter
  belongs_to :votable, polymorphic: true, inverse_of: :r_votes_as_votable

  validates_inclusion_of :weight, in: [-1, 1]
  validates :voter_id, uniqueness: { scope: %i[voter_type votable_id votable_type] }

  scope :up, -> { where(weight: 1) }
  scope :down, -> { where(weight: -1) }

  def up?
    weight == 1
  end

  def down?
    weight == -1
  end
end

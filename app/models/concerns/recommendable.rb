module Recommendable
  extend ActiveSupport::Concern

  included do
    has_one :r_document, as: :recommendable, inverse_of: :recommendable
    has_many :r_votes_as_voter, as: :voter, inverse_of: :voter, class_name: 'RVote'
    has_many :r_votes_as_votable, as: :votable, inverse_of: :voter, class_name: 'RVote'

  end
end

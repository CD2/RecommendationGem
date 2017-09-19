# frozen_string_literal: true

module Recommendation
  module Recommendable
    module Votes
      extend ActiveSupport::Concern

      included do
        has_many :votes_as_voter, {
          as: :voter,
          inverse_of: :voter,
          class_name: '::Recommendation::Vote'
        }
        has_many :votes_as_votable, {
          as: :votable,
          inverse_of: :votable,
          class_name: '::Recommendation::Vote'
        }

        def self.voted_up_by(voter)
          votes = voter.votes_as_voter.up.where(votable_type: all.klass.name)
          where(id: votes.select(:votable_id))
        end

        def self.voted_down_by(voter)
          votes = voter.votes_as_voter.down.where(votable_type: all.klass.name)
          where(id: votes.select(:votable_id))
        end

        def self.voted_on_by(voter)
          votes = voter.votes_as_voter.where(votable_type: all.klass.name)
          where(id: votes.select(:votable_id))
        end

        def self.not_voted_on_by(voter)
          votes = voter.votes_as_voter.where(votable_type: all.klass.name)
          where.not(id: votes.select(:votable_id))
        end
      end

      def vote_up(votable)
        vote = votes_as_voter.find_or_initialize_by(votable: votable)
        return false unless vote.update(weight: 1)
        association(:recommendation_document).reset
        true
      end

      def vote_down(votable)
        vote = votes_as_voter.find_or_initialize_by(votable: votable)
        return false unless vote.update(weight: -1)
        association(:recommendation_document).reset
        true
      end

      def unvote(votable)
        vote = votes_as_voter.find_by(votable: votable)
        return false unless vote&.destroy
        association(:recommendation_document).reset
        true
      end
    end
  end
end

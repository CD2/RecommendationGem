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
          votes = voter.votes_as_voter.up.where votable_type: all.klass.name
          where(id: votes.select(:votable_id))
        end

        def self.voted_down_by(voter)
          votes = voter.votes_as_voter.down.where votable_type: all.klass.name
          where(id: votes.select(:votable_id))
        end

        def self.voted_on_by(voter)
          votes = voter.votes_as_voter.where votable_type: all.klass.name
          where(id: votes.select(:votable_id))
        end

        def self.which_voted_up(votable)
          votes = votable.votes_as_votable.up.where voter_type: all.klass.name
          where(id: votes.select(:voter_id))
        end

        def self.which_voted_down(votable)
          votes = votable.votes_as_votable.down.where voter_type: all.klass.name
          where(id: votes.select(:voter_id))
        end

        def self.which_voted_on(votable)
          votes = votable.votes_as_votable.where voter_type: all.klass.name
          where(id: votes.select(:voter_id))
        end

        def self.top
          scores = left_joins(:votes_as_votable).group(:id).select(:id, 'coalesce(SUM(recommendation_votes.weight), 0) AS value')
          joins(%(JOIN (#{scores.to_sql}) AS recommendation_voting_scores ON recommendation_voting_scores.id = "#{table_name}".id))
          .order('recommendation_voting_scores.value DESC')
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

      def my_vote(votable)
        votes_as_voter.find_by(votable: votable)
      end

      def my_vote_weight(votable)
        my_vote(votable)&.weight || 0
      end

      def voted_up?(votable)
        my_vote_weight(votable) == 1
      end

      def voted_down?(votable)
        my_vote_weight(votable) == -1
      end
    end
  end
end

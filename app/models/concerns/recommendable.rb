module Recommendable
  extend ActiveSupport::Concern

  included do
    has_one :r_document, as: :recommendable, inverse_of: :recommendable
    has_many :r_votes_as_voter, as: :voter, inverse_of: :voter, class_name: 'RVote'
    has_many :r_votes_as_votable, as: :votable, inverse_of: :voter, class_name: 'RVote'

    def r_document
      super || create_r_document!
    end

    def tag_with(*args)
      args.extract_options!.each do |tag, weight|
        r_document.static_tags[tag.to_s] = weight
      end
      args.each do |tags|
        Array.wrap(tags).each { |tag| r_document.static_tags[tag.to_s] ||= 1 }
      end
      r_document.save
    end

    def tags_hash
      r_document.tags_cache
    end

    def tags
      tags_hash.map do |tag, weight|
        { name: tag, weight: weight }
      end
    end

    def r_score_for(subject)
      # subject.tags_hash.each do |tag, weight|
      #   tag.
      # end
    end

    def self.recommend_to(subject)

    end

    # a multiplier for how much vote on this thing is worth
    def self.vote_weight
      1
    end

    def vote_up(votable)
      vote = r_votes_as_voter.find_or_initialize_by(votable: votable)
      vote.update(weight: 1)
    end

    def vote_down(votable)
      vote = r_votes_as_voter.find_or_initialize_by(votable: votable)
      vote.update(weight: -1)
    end

    def unvote(votable)
      r_votes_as_voter.find_by(votable: votable)&.destroy
    end
  end
end

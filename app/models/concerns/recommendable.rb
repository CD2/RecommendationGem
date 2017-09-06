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
      args.each { |tag| r_document.static_tags[tag.to_s] ||= 1 }
      r_document.save
    end
  end
end

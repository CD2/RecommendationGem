class RDocument < ApplicationRecord
  belongs_to :recommendable, polymorphic: true, inverse_of: :r_document

  before_save :remove_zero_tags
  before_save :update_tags_cache

  def self.all_tags
    pluck('DISTINCT jsonb_object_keys(tags_cache)')
  end

  def votes
    RVote.where(voter_id: recommendable_id, voter_type: recommendable_type)
  end

  def cache_change(tag, change)
    tags_cache[tag] = (tags_cache[tag] || 0) + change
  end

  def remove_zero_tags
    static_tags.reject! { |k, v| v == 0 }
    tags_cache.reject! { |k, v| v == 0 }
  end

  def update_tags_cache
    if tags_cache.blank?
      self.tags_cache = recalculate_tags
      return
    end
    if static_tags_changed?
      static_tags_was.each do |tag, weight|
        cache_change tag, static_tags[tag] - weight
      end
    end
  end

  def recalculate_tags
    # dynamic = votes.joins('INNER JOIN "r_documents" ON "r_documents"."recommendable_id" = "r_votes"."votable_id" AND "r_documents"."recommendable_type" = "r_votes"."votable_type"')
    #
    # 'jsonb_object_keys(r_documents.tags_cache)'
    # byebug
    dynamic = {}
    static_tags.merge(dynamic) { |k, v1, v2| v1 + v2 }
  end

  def increment vote
    vote.votable.tags_hash.each do |tag, weight|
      cache_change tag, vote.weight * weight * vote.votable.class.vote_weight
    end
    save!
  end

  def decrement vote
    vote.votable.tags_hash.each do |tag, weight|
      cache_change tag, -1 * vote.weight * weight * vote.votable.class.vote_weight
    end
    save!
  end

  def invert vote
    vote.votable.tags_hash.each do |tag, weight|
      cache_change tag, 2 * vote.weight * weight * vote.votable.class.vote_weight
    end
    save!
  end
end

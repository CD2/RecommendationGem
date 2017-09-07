class RDocument < ApplicationRecord
  belongs_to :recommendable, polymorphic: true, inverse_of: :r_document

  before_save :update_tags_cache
  before_save :remove_zero_tags

  def self.all_tags
    pluck('DISTINCT jsonb_object_keys(tags_cache)')
  end

  def self.raw
    connection.execute(all.to_sql).to_a
  end

  def cache_change(tag, change)
    tags_cache[tag] = (tags_cache[tag] || 0) + change
  end

  def remove_zero_tags
    static_tags.reject! { |k, v| v == 0 }
    tags_cache.reject! { |k, v| v == 0 }
  end

  def update_tags_cache
    if static_tags_changed?
      (static_tags_was.keys | static_tags.keys).each do |tag|
        cache_change tag, (static_tags[tag] || 0) - (static_tags_was[tag] || 0)
      end
    end
  end

  def recalculate_tags
    dynamic_tags = {}
    RDocument
    .select('t.key AS tag, SUM(t.value::numeric * r_votes.weight) AS weight')
    .joins('INNER JOIN r_votes ON votable_id = recommendable_id AND votable_type = recommendable_type')
    .joins('JOIN jsonb_each_text(tags_cache) AS t ON TRUE')
    .where('r_votes.voter_id': recommendable_id, 'r_votes.voter_type': recommendable_type)
    .group('tag')
    .raw.each { |x| dynamic_tags[x['tag']] = x['weight'].to_f }
    self.tags_cache = static_tags.merge(dynamic_tags) { |k, v1, v2| v1 + v2 }
  end

  def increment vote
    vote.votable.tags_hash.each do |tag, weight|
      cache_change tag, vote.weight * weight
    end
    save!
  end

  def decrement vote
    vote.votable.tags_hash.each do |tag, weight|
      cache_change tag, -1 * vote.weight * weight
    end
    save!
  end

  def invert vote
    vote.votable.tags_hash.each do |tag, weight|
      cache_change tag, 2 * vote.weight * weight
    end
    save!
  end
end

class RDocument < ApplicationRecord
  belongs_to :recommendable, polymorphic: true, inverse_of: :r_document

  before_save :remove_zero_tags
  before_save :update_tags_cache

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
      # something with static_tags_was
    end
  end

  def recalculate_tags
    # TODO
    static_tags
  end
end

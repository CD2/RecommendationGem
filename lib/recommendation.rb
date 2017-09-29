# frozen_string_literal: true

require 'recommendation/engine'

module Recommendation
  def self.all_tags
    ::Recommendation::Document.class_eval do
      remove_special_tags(all_tags)
    end
  end

  def self.all_special_tags
    ::Recommendation::Document.class_eval do
      only_special_tags(all_tags)
    end
  end
end

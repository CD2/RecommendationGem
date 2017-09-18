# frozen_string_literal: true

require_dependency "#{::Recommendation::Engine.root}/lib/q/expand_json.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/q/join.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/q/metric.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/q/query_chain.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/q/simple_count.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/q/table_mock.rb"

module Recommendation
  def self.all_tags
    ::Recommendation::Document.all_tags
  end

  class ApplicationRecord < Q::Core
    self.abstract_class = true

    delegate :normalize, to: :class

    def self.normalize(str)
      str.to_s.parameterize.tr('_-', ' ')
    end
  end
end

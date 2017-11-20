# frozen_string_literal: true

require_dependency "#{::Recommendation::Engine.root}/lib/recommendation/q/expand_json.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/recommendation/q/join.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/recommendation/q/metric.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/recommendation/q/query_chain.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/recommendation/q/simple_count.rb"
require_dependency "#{::Recommendation::Engine.root}/lib/recommendation/q/table_mock.rb"

module Recommendation
  class RecommendationRecord < ::Recommendation::Q::Core
    self.abstract_class = true

    delegate :normalize, to: :class

    def self.normalize(str)
      str.to_s.parameterize.tr('_-', ' ').downcase
    end
  end
end

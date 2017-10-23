# frozen_string_literal: true

module Recommendable
  extend ActiveSupport::Concern

  include ::Recommendation::Recommendable::Core
  include ::Recommendation::Recommendable::Distance
  include ::Recommendation::Recommendable::Metrics
  include ::Recommendation::Recommendable::Tags
  include ::Recommendation::Recommendable::Votes
end

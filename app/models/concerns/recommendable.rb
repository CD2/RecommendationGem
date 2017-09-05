# frozen_string_literal: true

module Recommendable
  extend ActiveSupport::Concern

  included do
    has_one :recommendation_document, as: :recommendable, inverse_of: :recommendable

  end
end

class User < ApplicationRecord
  include Recommendable

  validates :name, presence: true
end

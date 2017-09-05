class Article < ApplicationRecord
  include Recommendable

  validates :name, presence: true
end

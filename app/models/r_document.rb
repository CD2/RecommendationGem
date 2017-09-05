class RDocument < ApplicationRecord
  belongs_to :recommendable, polymorphic: true, inverse_of: :r_document
end

FactoryGirl.define do
  factory :r_document do
    recommendable { create :user }
  end
end

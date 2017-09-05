FactoryGirl.define do
  factory :recommendation_document do
    recommendable { create :user }
  end
end

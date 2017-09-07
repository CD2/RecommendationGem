FactoryGirl.define do
  factory :recommendation_document, class: 'Recommendation::Document' do
    recommendable { create :user }
  end
end

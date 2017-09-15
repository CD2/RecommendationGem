# frozen_string_literal: true

FactoryGirl.define do
  factory :recommendation_vote, class: 'Recommendation::Vote' do
    voter { create :user }
    votable { create :article }
    weight 1
  end
end

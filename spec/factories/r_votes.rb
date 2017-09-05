FactoryGirl.define do
  factory :r_vote do
    voter { create :user }
    votable { create :article }
    weight 1
  end
end

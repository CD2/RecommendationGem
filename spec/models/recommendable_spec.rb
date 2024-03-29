# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'recommendable' do
  subject(:user) { FactoryGirl.create :user }

  # let!(:a1) {
  #   x = FactoryGirl.create :article
  #   x.tag_with(:race_cars, :speed_holes, :go_faster_stripes)
  #   x
  # }
  # let!(:a2) {
  #   x = FactoryGirl.create :article
  #   x.tag_with(:race_cars, :flame_decals, :speed_holes)
  #   x
  # }
  # let!(:a3) {
  #   x = FactoryGirl.create :article
  #   x.tag_with()
  #   x
  # }
  #
  # before(:each) do
  #   user.tag_with(race_cars: 10, flame_decals: 5)
  # end

  describe '#tag_with' do
    let(:target) { FactoryGirl.create(:article) }

    describe 'assign and retrieve tags' do
      it 'assign tag1 without weight' do
        target.tag_with(:tag1)
        expect(target.tags_hash['tag1']).to match(1)
      end

      it 'assign tag1 with weight' do
        target.tag_with(tag1: 10)
        expect(target.tags_hash['tag1']).to match(10)
      end

      it '.tag should return array hash' do
        target.tag_with(:tag1)
        target.tag_with(:tag2)
        expect(target.tags).to match([{ name: 'tag1', weight: 1 }, { name: 'tag2', weight: 1 }])
      end

      it '.tag_hash should return tags_cache' do
        target.tag_with(:tag1)
        target.tag_with(:tag2)
        expect(target.tags_hash).to match('tag1' => 1, 'tag2' => 1)
      end

      it 'when the tag already exists, it is not overwritten' do
        target.tag_with(tag1: 10)
        target.tag_with(:tag1)
        expect(target.tags_hash['tag1']).to eq(10)
      end
    end

    describe 'assigning multiple tags at a time' do
      it 'considers a hash of tags as tag_name/weight pairs' do
        target.tag_with(tag1: 1, tag2: 2, tag3: 3)
        expect(target.tags_hash).to match(tag1: 1, tag2: 2, tag3: 3)
      end

      it 'overwrites existing tags when supplied with hash' do
        target.tag_with(tag1: 1, tag2: 2, tag3: 3)
        target.tag_with(tag1: 10, tag2: 20, tag3: 30)
        expect(target.tags_hash).to match(tag1: 10, tag2: 20, tag3: 30)
      end
    end
  end

  describe '#recommend_to' do
    let(:target1) { FactoryGirl.create(:article) }
    let(:target2) { FactoryGirl.create(:article) }
    let(:target3) { FactoryGirl.create(:article) }
    let(:user) { FactoryGirl.create(:user) }
    context 'when all article and user tags have weight 1' do
      it 'orders the results by the number of common tags' do
        target1.tag_with(:tag1)
        target2.tag_with(:tag1, :tag2)
        user.tag_with(:tag1, :tag2)
        expect(Article.recommend_to(user)).to eq([target2, target1])
      end
    end

    context 'when all article tags have weight 1' do
      it 'orders the results by the sum of user\'s relevant tag weights' do
        target1.tag_with(:tag1)
        target2.tag_with(:tag2)
        target3.tag_with(:tag3)
        user.tag_with(tag1: 2, tag2: 5, tag3: 9)
        expect(Article.recommend_to(user)).to eq([target3, target2, target1])
      end
    end

    context 'when all user tags have weight 1' do
      it 'orders the results by the sum of articles\'s relevant tag weights' do
        user.tag_with(:tag1, :tag2, :tag3)
        target1.tag_with(tag1: 4)
        target2.tag_with(tag2: 6)
        target3.tag_with(tag3: 8)
        expect(Article.recommend_to(user)).to eq([target3, target2, target1])
      end
    end

    context 'when both tags have weights >||< 1' do
      it 'recommends based on both weights sum' do
        user.tag_with(tag1: 2, tag2: 9, tag3: 7)
        target1.tag_with(tag1: 8)
        target2.tag_with(tag2: -1)
        target3.tag_with(tag3: 7)
        expect(Article.recommend_to(user)).to eq([target3, target1, target2])
      end
      it 'should weight user tags more than article one\'s, I think?'
      it 'is better to see something somewhat relevant to a major interest that to see something very relevant to a minor interest, maybe?'
    end
  end

  describe 'VOTING' do
    let(:target) { FactoryGirl.create(:article) }
    let(:user) { FactoryGirl.create(:user) }

    before(:each) do
      target.tag_with(tag1: 1)
    end

    describe 'upvoting' do
      it 'vote up' do
        expect { user.vote_up(target) }.to change(Recommendation::Vote, :count).by(1)
      end

      it 'adds tags' do
        user.vote_up(target)
        expect(User.last.tags_hash).to include('tag1' => 1)
      end

      it 'updates tags' do
        user.tag_with(tag1: 1)
        user.vote_up(target)
        expect(User.last.tags_hash).to include('tag1' => 2)
      end
    end

    describe 'downvoting' do
      it 'vote down' do
        expect { user.vote_down(target) }.to change(Recommendation::Vote, :count).by(1)
      end

      it 'adds tags' do
        user.vote_down(target)
        expect(User.last.tags_hash).to include('tag1' => -1)
      end

      it 'updates tags' do
        user.tag_with(tag1: -1)
        user.vote_down(target)
        expect(User.last.tags_hash).to include('tag1' => -2)
      end
    end

    describe 'unvoting' do
      it 'unvote' do
        user.tag_with(:tag1)
        user.vote_up(target)
        expect { user.unvote(target) }.to change(Recommendation::Vote, :count).by(-1)
      end

      it 'updates tags vote_up' do
        user.tag_with(tag1: 5)
        user.vote_up(target)
        user.unvote(target)
        expect(User.last.tags_hash).to include('tag1' => 5)
      end

      it 'updates tags vote_down' do
        user.tag_with(tag1: 5)
        user.vote_down(target)
        user.unvote(target)
        user.vote_up(target)
        expect(User.last.tags_hash).to include('tag1' => 6)
      end
    end

    it 'vote up then down' do
      user.vote_up(target)
      user.vote_down(target)
      expect(Recommendation::Vote.last.weight).to eq(-1)
    end

    it 'vote down then up' do
      user.vote_down(target)
      user.vote_up(target)
      expect(Recommendation::Vote.last.weight).to eq(1)
    end

    describe 'the tag cache is correctly updated' do
      it 'unvoting exactly undoes voting up' do
        expect {
          user.vote_up(target)
          user.unvote(target)
        }.to_not change { user.tags_hash }
      end

      it 'unvoting exactly undoes voting down' do
        expect {
          user.vote_down(target)
          user.unvote(target)
        }.to_not change { user.tags_hash }
      end

      it 'upvoting has the same result despite a previous vote' do
        user2 = FactoryGirl.create :user
        user.vote_up(target)
        user2.vote_down(target)
        user2.vote_up(target)
        expect(user.tags_hash).to eq user2.tags_hash
      end

      it 'downvoting has the same result despite a previous vote' do
        user2 = FactoryGirl.create :user
        user.vote_down(target)
        user2.vote_up(target)
        user2.vote_down(target)
        expect(user.tags_hash).to eq user2.tags_hash
      end
    end
  end
end

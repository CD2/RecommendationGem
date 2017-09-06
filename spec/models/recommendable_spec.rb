require 'rails_helper'

RSpec.describe 'recommendable' do
  subject(:user) { FactoryGirl.create :user }

  let!(:a1) {
    x = FactoryGirl.create :article
    x.tag_with(:race_cars, :speed_holes, :go_faster_stripes)
    x
  }
  let!(:a2) {
    x = FactoryGirl.create :article
    x.tag_with(:race_cars, :flame_decals, :speed_holes)
    x
  }
  let!(:a3) {
    x = FactoryGirl.create :article
    x.tag_with()
    x
  }

  before(:each) do
    user.tag_with(race_cars: 10, flame_decals: 5)
  end

  describe '#tag_with' do

    let(:target) { FactoryGirl.create(:article) }

    describe 'assign and retrieve tags' do

      it 'assign tag1 without weight' do
        target.tag_with(:tag1)
        expect(target.tags).to match( [{'tag1':1}] )
      end

      it 'assign tag1 with weight' do
        target.tag_with(tag1: 10)
        expect(target.tags).to match( [{'tag1':10}] )
      end

      it '.tag should return array of hashs' do
        target.tag_with(:tag1)
        target.tag_with(:tag2)
        expect(target.tags).to match( [{'tag1':1}, {'tag2':1}] )
      end

      it 'when the tag already exists, it is not overwritten' do
        target.tag_with(:tag1: 10)
        target.tag_with(:tag1)
        expect(target.tags.first.weight).to eq(10)
      end
    end
    describe 'assigning multiple tags at a time' do
      it 'should consider a hash of tags as tag_name/weight pairs' do
        target.tag_with( [{tag1:1}, {tag2:2}, {tag3:3}] )
        expect(target.tags).to match([{tag1:1}, {tag2:2}, {tag3:3}])
      end

      it 'should overwrite existing tags when supplied with hash' do
        target.tag_with( [{tag1:1}, {tag2:2}, {tag3:3}] )
        target.tag_with( [{tag1:10}, {tag2:20}, {tag3:30}] )
        expect(target.tags).to match([{tag1:10}, {tag2:20}, {tag3:30}])
      end

    end
  end

  describe '#recommend_to' do
    context 'when all article and user tags have weight 1' do
      it 'orders the results by the number of common tags'
    end

    context 'when all article tags have weight 1' do
      it 'orders the results by the sum of user\'s relevant tag weights'
    end

    context 'when all user tags have weight 1' do
      it 'orders the results by the sum of articles\'s relevant tag weights'
    end

    context 'when both have non-trivial tags' do
      it 'does something else...'
      it 'should weight user tags more than article one\'s, I think?'
      it 'is better to see something somewhat relevant to a major interest that to see something very relevant to a minor interest, maybe?'
    end

    it 'should consider the number of unrelated tags (negatively)?'
    it 'should consider popularity?'

    context 'with a defined timeliness_modifier' do
      it ''
    end

    context 'with a defined location_modifier' do
      it ''
    end
  end

  describe 'VOTING' do
    it 'should increment the tags_cache'
  end
end

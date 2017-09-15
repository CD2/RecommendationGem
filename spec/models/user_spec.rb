# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
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
    x.tag_with
    x
  }

  before(:each) do
    user.tag_with(race_cars: 10, flame_decals: 5)
  end

  describe '#tag_with' do
    it 'assigns every tag to static_tags with a weight of 1'
    it 'when the tag already exists, it is not overwritten'
    context 'when given a hash' do
      it 'considers keys as tags and values as weight'
      it 'overwrites existing tags'
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

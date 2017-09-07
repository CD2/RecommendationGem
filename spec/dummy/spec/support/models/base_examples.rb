require 'rails_helper'

skips = []

RSpec.shared_context 'a model' do
  it 'has a valid factory' do
    expect {
      FactoryGirl.create(described_class.name.gsub('::', '_').underscore)
    }.to_not raise_error
  end

  it 'can be joined to all it\'s associations without error' do
    described_class.reflect_on_all_associations.each do |reflection|
      next if reflection.polymorphic?
      next if skips.include? [described_class, reflection.name]
      expect {
        described_class.joins(reflection.name).load
      }.to_not raise_error
    end
  end
end

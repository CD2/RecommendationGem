# frozen_string_literal: true

require 'rails_helper'
require 'support/models/base_examples.rb'

Dir['./app/models/**/*.rb'].each { |file| require file }

ApplicationRecord.descendants.each do |m|
  RSpec.describe m, type: :model do
    it_behaves_like 'a model'
  end
end

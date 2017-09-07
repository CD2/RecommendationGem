# frozen_string_literal: true

task reset_all: :environment do
  Rake::Task['db:drop'].invoke
  Rake::Task['db:create'].invoke
  Rake::Task['seed'].invoke
end

task seed: :environment do
  Rake::Task['db:migrate'].invoke
end

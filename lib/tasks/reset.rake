task reset_all: :environment do
  Rake::Task['db:drop'].invoke
  Rake::Task['db:create'].invoke
  Rake::Task['seed'].invoke
end

task seed: :environment do
  Rake::Task['db:migrate'].invoke

  user = User.create!(name: 'A. Person')
  doc = user.create_r_document!(static_tags: { racecars: 10 })

end

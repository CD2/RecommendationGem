namespace :recommendation do
  desc 'Create Recommendation::Documents for all Recommendables, speeding up future load-time'
  task create_docs: :environment do
    Dir['./app/models/**/*.rb'].each { |file| require_dependency file }
    models = ::ApplicationRecord.descendants.select { |x| x.include?(Recommendable) }
    models.each { |model| model.all.each { |record| record.recommendation_document } }
  end
end

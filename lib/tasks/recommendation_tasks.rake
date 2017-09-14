namespace :recommendation do
  desc 'Create Recommendation::Documents for all Recommendables, speeding up future load-time'
  task create_docs: :environment do
    Dir['./app/models/**/*.rb'].each { |file| require_dependency file }
    models = ::ApplicationRecord.descendants.select { |x| x.include?(Recommendable) }
    puts 'Creating Documents:'
    old_num = Recommendation::Document.count
    models.each do |model|
      total = model.count
      model.all.each_with_index do |record, i|
        print "#{model.name} #{i + 1}/#{total}\r"
        record.recommendation_document
      end
      puts
    end
    puts "Created #{Recommendation::Document.count - old_num} Documents"
  end
end

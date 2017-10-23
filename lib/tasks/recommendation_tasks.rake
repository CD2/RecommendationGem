# frozen_string_literal: true

namespace :recommendation do
  desc 'Create Recommendation::Documents for all Recommendables, speeding up future load-time'
  task create_docs: :environment do
    Dir['./app/models/**/*.rb'].each { |file| require_dependency file }
    models = ::ApplicationRecord.descendants.select { |x| x.include?(Recommendable) }
    old_num = Recommendation::Document.count
    models.each do |model|
      Recommendation::Document.sql_execute %{
        INSERT INTO recommendation_documents(recommendable_id, recommendable_type, created_at, updated_at)
        SELECT id, '#{model}', current_timestamp, current_timestamp
        FROM #{model.table_name}
        WHERE id NOT IN (
          SELECT recommendable_id
          FROM recommendation_documents
          WHERE recommendable_type = '#{model}'
        )
      }
    end
    puts "Created #{Recommendation::Document.count - old_num} Documents"
  end
end

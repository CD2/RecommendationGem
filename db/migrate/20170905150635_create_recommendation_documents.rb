class CreateRecommendationDocuments < ActiveRecord::Migration[5.1]
  def change
    create_table :recommendation_documents do |t|
      t.references :recommendable, polymorphic: true, index: false
      t.jsonb :static_tags, default: {}, null: false
      t.jsonb :tags_cache, default: {}, null: false

      t.timestamps
    end

    add_index :recommendation_documents, %i[recommendable_id recommendable_type], unique: true, name: :index_recommendation_documents_on_recommendable
    add_index :recommendation_documents, :static_tags, using: :gin
    add_index :recommendation_documents, :tags_cache, using: :gin
  end
end

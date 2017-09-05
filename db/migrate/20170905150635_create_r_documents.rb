class CreateRDocuments < ActiveRecord::Migration[5.1]
  def change
    create_table :r_documents do |t|
      t.references :recommendable, polymorphic: true, unique: true
      t.jsonb :static_tags, default: {}, null: false
      t.jsonb :tags_cache, default: {}, null: false

      t.timestamps
    end

    add_index :r_documents, :static_tags, using: :gin
    add_index :r_documents, :tags_cache, using: :gin
  end
end

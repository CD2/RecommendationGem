# This migration comes from recommendation (originally 20170905154523)
class CreateRecommendationVotes < ActiveRecord::Migration[5.1]
  def change
    create_table :recommendation_votes do |t|
      t.references :voter, polymorphic: true
      t.references :votable, polymorphic: true
      t.integer :weight, null: false

      t.timestamps
    end

    add_index :recommendation_votes, %i[voter_id voter_type votable_id votable_type], unique: true, name: :one_vote_per_voter_per_votable
  end
end

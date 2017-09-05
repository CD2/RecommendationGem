class CreateRVotes < ActiveRecord::Migration[5.1]
  def change
    create_table :r_votes do |t|
      t.references :voter, polymorphic: true
      t.references :votable, polymorphic: true
      t.integer :weight, null: false

      t.timestamps
    end

    add_index :r_votes, %i[voter_id voter_type votable_id votable_type], unique: true, name: :one_vote_per_voter_per_votable
  end
end

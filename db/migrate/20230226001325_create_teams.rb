class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.text :team_type
      t.text :ds
      t.text :name
      t.text :riders

      t.timestamps
    end
  end
end

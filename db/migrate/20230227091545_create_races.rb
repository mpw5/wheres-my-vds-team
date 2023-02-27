class CreateRaces < ActiveRecord::Migration[7.0]
  def change
    create_table :races do |t|
      t.text :race_type
      t.text :name
      t.text :pcs_name
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end

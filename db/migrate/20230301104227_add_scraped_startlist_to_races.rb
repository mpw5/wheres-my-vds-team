class AddScrapedStartlistToRaces < ActiveRecord::Migration[7.0]
  def change
    add_column :races, :scraped_startlist, :text
  end
end

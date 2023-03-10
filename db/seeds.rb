require 'csv'

Team.destroy_all
# Race.destroy_all

teams = CSV.read(Rails.root.join('db', 'seeds', 'teams.csv'))

teams.each do |team|
  team_type, ds, name, riders = team
  Team.find_or_create_by!(team_type:, ds:, name:, riders:)
end

races = CSV.read(Rails.root.join('db', 'seeds', 'races.csv'))

races.each do |race|
  race_type, name, pcs_name, day, month, year, length = race

  start_date = Date.parse("#{day}-#{month}-#{year}")
  end_date = length.nil? ? start_date : start_date + length.to_i - 1

  Race.find_or_create_by!(race_type:, name:, pcs_name:, start_date:, end_date:)
end

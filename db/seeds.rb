require 'csv'

data = CSV.read(Rails.root.join('db', 'seeds', 'teams.csv'))

data.each do |row|
  team_type, ds, name, riders = row
  Team.find_or_create_by!(team_type:, ds:, name:, riders:)
end

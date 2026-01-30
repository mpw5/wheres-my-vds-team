# frozen_string_literal: true

require 'csv'

module Vds
  class Scraper
    def self.year = Time.zone.today.year

    def self.teams
      Vds::Scraper.populate_teams_csv(gender: 'MALE')
      Vds::Scraper.populate_teams_csv(gender: 'FEMALE')
    end

    def self.races
      Vds::Scraper.populate_races_csv(gender: 'MALE')
      Vds::Scraper.populate_races_csv(gender: 'FEMALE')
    end

    def self.riders
      Vds::Scraper.populate_riders_csv(gender: 'MALE')
      Vds::Scraper.populate_riders_csv(gender: 'FEMALE')
    end

    def self.run_query(query, gender)
      client = Vds::GraphQlClient::Client
      response = client.query(query, variables: { year: year, gender: gender })
      raise response.errors[:data].to_s if response.errors&.any?

      response
    end

    def self.populate_teams_csv(gender:)
      teams = run_query(Vds::Queries::TEAMS, gender).data.teams.nodes

      CSV.open('lib/data/teams.csv', 'a') do |csv|
        teams.each do |team|
          csv << [gender.downcase, team.to_h.dig('manager', 'displayName'), team.to_h['startDate'], team.to_h['riders']]
        end
      end
    end

    def self.populate_races_csv(gender:)
      races = run_query(Vds::Queries::RACES, gender).data.races.nodes

      CSV.open('lib/data/races.csv', 'a') do |csv|
        races.each do |race|
          name = race.to_h.dig('race', 'name')

          csv << [gender.downcase, name.parameterize, race.to_h['startDate'], race.to_h['stageCount']]
        end
      end
    end

    def self.populate_riders_csv(gender:)
      riders = run_query(Vds::Queries::RIDERS, gender).data.riders.nodes

      CSV.open('lib/data/riders.csv', 'a') do |csv|
        riders.each do |rider|
          rider = rider.to_h
          rider_season = rider['season'].to_h

          csv << [gender.downcase, rider['displayName'], rider['nationality'], rider_season['team'],
                  rider_season['cost'], rider_season['previousYearCost'], rider_season['previousYearScore']]
        end
      end
    end
  end
end

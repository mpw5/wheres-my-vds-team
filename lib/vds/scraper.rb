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

    def self.run_query(query, gender, after: nil)
      client = Vds::GraphQlClient::Client
      variables = { year:, gender: }
      variables[:after] = after if after
      response = client.query(query, variables:)
      raise response.errors.to_s if response.errors&.any?

      response
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.populate_teams_csv(gender:)
      after = nil

      loop do
        response = run_query(Vds::Queries::TEAMS, gender, after: after)
        teams_data = response.data.teams
        teams = teams_data.nodes

        CSV.open(Rails.root.join('lib/data/teams.csv'), 'a') do |csv|
          teams.each do |team|
            team = team.to_h
            next unless team['locked']

            roster = team['riders']['nodes'].map { |rider| rider['rider']['displayName'] }.join(',')
            csv << [gender.downcase, team.dig('manager', 'displayName'), team['name'], roster]
          end
        end
        break unless teams_data.page_info.has_next_page

        after = teams_data.page_info.end_cursor
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def self.populate_races_csv(gender:)
      races = run_query(Vds::Queries::RACES, gender).data.races.nodes

      CSV.open(Rails.root.join('lib/data/races.csv'), 'a') do |csv|
        races.each do |race|
          race = race.to_h
          name = race.dig('race', 'name')

          csv << [gender.downcase, name, name.parameterize, race['startDate'], race['stageCount']]
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def self.populate_riders_csv(gender:)
      riders = run_query(Vds::Queries::RIDERS, gender).data.riders.nodes

      CSV.open(Rails.root.join('lib/data/riders.csv'), 'a') do |csv|
        riders.each do |rider|
          rider = rider.to_h
          rider_season = rider['season'].to_h

          csv << [gender.downcase, rider['displayName'], rider['nationality'], rider_season['team'],
                  rider_season['cost'], rider_season['previousYearCost'], rider_season['previousYearScore']]
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end

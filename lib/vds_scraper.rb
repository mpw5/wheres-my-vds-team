require 'nokogiri'
require 'open-uri'
require 'csv'
# require_relative 'lib/get_info'
require 'pry'

class VdsScraper
  def self.mens_teams_url
    'https://pdcvds.com/teams.php?mw=1&y=2023'
  end

  def self.womens_teams_url
    'https://pdcvds.com/teams.php?mw=0&y=2023'
  end

  def self.mens_races_url
    'https://pdcvds.com/cal.php?mw=1&y=2023'
  end

  def self.womens_races_url
    'https://pdcvds.com/cal.php?mw=0&y=2023'
  end

  def self.connect_to_page(url)
    Nokogiri::HTML(URI.open(url))
  end

  def self.teams
    CSV.open('lib/data/teams.csv', 'wb', force_quotes: false) do |csv|
      mens_teams = connect_to_page(mens_teams_url).at('table')

      mens_teams.search('tr').each do |team|
        type = 'mens'
        ds = team.css('td')[1]&.text
        team_name = team.css('td')[2]&.text
        team_link = team.css('td')[2]&.children&.first&.attributes&.dig('href')&.value
        puts "#{team_name} - #{ds}"

        next if team_link.nil?
        team_array = []
        team_list = connect_to_page("#{mens_teams_url}#{team_link}").at('table')
        team_list.search('tr').each do |rider|
          rider_name = rider.children[9].children.first.children.text
          team_array << rider_name unless rider_name.empty?
        end

        csv << [type, ds, team_name, team_array].reject(&:empty?)
      end

      womens_teams = connect_to_page(womens_teams_url).at('table')

      womens_teams.search('tr').each do |team|
        type = 'womens'
        ds = team.css('td')[1]&.text
        team_name = team.css('td')[2]&.text
        team_link = team.css('td')[2]&.children&.first&.attributes&.dig('href')&.value
        puts "#{team_name} - #{ds}"

        next if team_link.nil?
        team_array = []
        team_list = connect_to_page("#{womens_teams_url}#{team_link}").at('table')
        team_list.search('tr').each do |rider|
          rider_name = rider.children[7].children.first.children.text
          team_array << rider_name unless rider_name.empty?
        end

        csv << [type, ds, team_name, team_array]
      end
    end
  end

  def self.races
    CSV.open('lib/data/races.csv', 'wb', force_quotes: false) do |csv|
      mens_races = connect_to_page(mens_races_url).at('table')

      mens_races.search('tr').each do |race|
        type = 'mens'
        raw_name = race.css('td')[4]&.text
        name = raw_name&.slice(0..(raw_name&.index(' (')))&.strip
        day = race.css('td')[1]&.text
        month = race.css('td')[0]&.text
        year = '2023'
        length = race.css('td')[5]&.text

        csv << [type, name, day, month, year, length]
      end

      womens_races = connect_to_page(womens_races_url).at('table')

      womens_races.search('tr').each do |race|
        type = 'womens'
        raw_name = race.css('td')[4]&.text
        name = raw_name&.slice(0..(raw_name&.index(' (')))&.strip
        day = race.css('td')[1]&.text
        month = race.css('td')[0]&.text
        year = '2023'
        length = race.css('td')[5]&.text

        csv << [type, name, day, month, year, length]
      end
    end
  end
end

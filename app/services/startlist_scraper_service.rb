# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

class StartlistScraperService
  attr_reader :riders

  def initialize(race)
    @race = race
    @riders = []
  end

  def call
    doc = Nokogiri::HTML(URI.open("https://#{@race}"))
    startlist = doc.css('.startlist_v4')
    return [] if startlist.empty?

    startlist.first.children.each do |team|
      team_riders = team.css('.ridersCont')
      add_riders_for(team_riders)
    end

    riders
  end

  def add_riders_for(team)
    team.first.children.children.children.children.each do |rider|
      raw_name = rider.text
      next unless raw_name.length > 3

      riders << parse_name(raw_name)
    end
  end

  def parse_name(raw_name)
    name_as_array = raw_name.split
    rotated_name = if raw_name.in?(riders_with_middle_names)
                     name_as_array.rotate(name_as_array.length - 2)
                   else
                     name_as_array.rotate(name_as_array.length - 1)
                   end

    I18n.transliterate(rotated_name.join(' ').downcase)
  end

  # rubocop:disable Metrics/MethodLength
  def riders_with_middle_names
    [
      'LUDWIG Cecilie Uttrup',
      'MOLANO Juan Sebastian',
      'SÁNCHEZ Luis León',
      'ROJAS José Joaquín',
      'LÓPEZ Miguel Ángel',
      'MARTÍNEZ Daniel Felipe',
      'JOHANNESSEN Tobias Halland',
      'JOHANNESSEN Anders Halland',
      'LÓPEZ Juan Pedro',
      'LECERF William Junior'
    ]
  end
  # rubocop:enable Metrics/MethodLength
end

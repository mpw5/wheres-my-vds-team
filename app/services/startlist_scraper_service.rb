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
    begin
      url = "https://#{@race}"
      options = {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      }
      doc = Nokogiri::HTML(URI.open(url, options))
    rescue OpenURI::HTTPError => e
      Rails.logger.error "Failed to fetch: #{e.message}"
      Rails.logger.error "Response: #{e.io.read}" if e.io
      return []
    end
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
      'TEUTENBERG Tim Torn',
      'HONORÉ Mikkel Frølich',
      'PEDERSEN Rasmus Søjberg',
      'FAURA José Luis',
      'HERREÑO Martin Santiago',
      'KAJAMINI Florian Samuel',
      'MARTINEZ Guillermo Juan',
      'PEÑUELA Francisco Joel',
      'CEPEDA Jefferson Alveiro',
      'HAGENES Per Strand',
      'ANDRESEN Tobias Lund'
    ]
  end
end

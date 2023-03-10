# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

class StartlistScraperService
  def initialize(race)
    @race = race
  end

  def call
    doc = Nokogiri::HTML(URI.open("https://#{@race}"))
    startlist = doc.css('.blue')
    riders = []

    startlist.each do |rider|
      raw_name = rider.children.text
      next unless raw_name

      riders << parse_name(raw_name)
    end

    riders
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
    ['LUDWIG Cecilie Uttrup',
     'MOLANO Juan Sebastian',
     'SÁNCHEZ Luis León',
     'ROJAS José Joaquín',
     'LÓPEZ Miguel Ángel',
     'MARTÍNEZ Daniel Felipe']
  end
end

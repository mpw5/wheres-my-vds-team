# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'

class StartlistScraperService
  def initialize(race)
    @race = race
  end

  def call
    doc = Nokogiri::HTML(URI.open(@race))
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
    if raw_name.eql?('LUDWIG Cecilie Uttrup')
      'cecilie uttrup ludwig'
    else
      I18n.transliterate(name_as_array.rotate(name_as_array.length - 1).join(' ').downcase)
    end
  end
end

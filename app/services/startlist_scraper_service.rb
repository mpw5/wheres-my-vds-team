# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'pry'

class StartlistScraperService
  def initialize(race)
    @race = race
  end

  def call
    doc = Nokogiri::HTML(URI.open("https://www.procyclingstats.com/race/#{@race}/2023/startlist"))
    startlist = doc.css('.blue')
    riders = []

    startlist.each do |rider|
      raw_name = rider.attributes['href']
      next unless raw_name

      name = raw_name.value.partition('/').last.tr('-', ' ')
      riders << name
    end

    riders
  end
end

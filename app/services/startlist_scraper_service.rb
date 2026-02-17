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
    doc = fetch_race_page
    startlist = doc.css('.startlist_v4')
    return [] if startlist.empty?

    startlist.first.children.each do |team|
      team_riders = team.css('.ridersCont')
      add_riders_for(team_riders)
    end

    riders
  end

  def fetch_race_page
    url = "https://#{@race}"

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless=new')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')
    options.add_argument('--window-size=1400,900')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')

    # Use chromium binary if available (for Docker), otherwise default to chrome
    options.binary = '/usr/bin/chromium' if File.exist?('/usr/bin/chromium')

    driver = Selenium::WebDriver.for(:chrome, options: options)
    begin
      driver.get(url)
      html = driver.page_source
      Nokogiri::HTML(html)
    ensure
      driver.quit
    end
  end

  def add_riders_for(team)
    team.css('a').each do |rider|
      raw_name = rider.text.strip
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

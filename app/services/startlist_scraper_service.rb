# frozen_string_literal: true

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
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--disable-extensions')
    options.add_argument('--disable-software-rasterizer')
    options.add_argument('--js-flags=--max-old-space-size=256')
    options.add_argument('--window-size=1400,900')
    options.add_argument('--disable-blink-features=AutomationControlled')
    options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')

    # Use chromium binary if available (for Docker), otherwise default to chrome
    options.binary = '/usr/bin/chromium' if File.exist?('/usr/bin/chromium')

    driver = Selenium::WebDriver.for(:chrome, options: options)
    driver.manage.timeouts.page_load = 30
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
    parts = raw_name.split
    surname = parts.take_while { |part| part == part.upcase }
    first_names = parts.drop(surname.length)

    I18n.transliterate((first_names + surname).join(' ').downcase)
  end
end

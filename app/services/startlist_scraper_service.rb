# frozen_string_literal: true

require 'nokogiri'

class StartlistScraperService
  def initialize(races)
    @races = Array(races)
  end

  def call
    return if @races.empty?

    driver = build_driver
    @races.each do |race|
      scrape_race(driver, race)
      sleep 2 # be polite to PCS
    end
  ensure
    driver&.quit
  end

  def parse_name(raw_name)
    parts = raw_name.split
    surname = parts.take_while { |part| part == part.upcase }
    first_names = parts.drop(surname.length)

    I18n.transliterate((first_names + surname).join(' ').downcase)
  end

  private

  def scrape_race(driver, race)
    doc = fetch_race_page(driver, race.pcs_url)
    riders = extract_riders(doc)
    race.update!(scraped_startlist: riders.join(','))
  rescue StandardError => e
    Rails.logger.error("Failed to fetch startlist for #{race.pcs_name}: #{e.message}")
  end

  def fetch_race_page(driver, url)
    driver.get("https://#{url}")
    Nokogiri::HTML(driver.page_source)
  end

  def extract_riders(doc)
    riders = []
    startlist = doc.css('.startlist_v4')
    return riders if startlist.empty?

    startlist.first.children.each do |team|
      team.css('.ridersCont a').each do |rider|
        raw_name = rider.text.strip
        riders << parse_name(raw_name) if raw_name.length > 3
      end
    end

    riders
  end

  def build_driver
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
    options.binary = '/usr/bin/chromium' if File.exist?('/usr/bin/chromium')

    driver = Selenium::WebDriver.for(:chrome, options: options)
    driver.manage.timeouts.page_load = 30
    driver
  end
end

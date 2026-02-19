# frozen_string_literal: true

require 'json'
require 'net/http'
require 'nokogiri'
require 'selenium-webdriver'

APP_URL = ENV.fetch('APP_URL')
API_KEY = ENV.fetch('SCRAPER_API_KEY')

RACES_URL = 'https://www.procyclingstats.com/race'
YEAR = Time.now.year

def build_driver
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--window-size=1400,900')
  options.add_argument('--disable-blink-features=AutomationControlled')
  options.add_argument('--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ' \
                       'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36')

  driver = Selenium::WebDriver.for(:chrome, options: options)
  driver.manage.timeouts.page_load = 30

  # Remove the webdriver flag that Cloudflare detects
  driver.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: <<~JS)
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
  JS

  driver
end

def parse_name(raw_name)
  parts = raw_name.split
  surname = parts.take_while { |part| part == part.upcase }
  first_names = parts.drop(surname.length)
  (first_names + surname).join(' ').downcase
    .unicode_normalize(:nfkd)
    .gsub(/[\u0300-\u036f]/, '')
end

def wait_for_cloudflare(driver)
  15.times do |i|
    break unless driver.title.include?('Just a moment')

    puts "    Waiting for Cloudflare challenge (#{i + 1}s)..."
    sleep 1
  end
end

def scrape_race(driver, pcs_name)
  url = "#{RACES_URL}/#{pcs_name}/#{YEAR}/startlist"
  puts "  Fetching #{url}..."

  driver.get(url)
  wait_for_cloudflare(driver)
  doc = Nokogiri::HTML(driver.page_source)

  if driver.title.include?('Just a moment')
    puts "    Cloudflare still blocking — skipping"
    return []
  end

  doc.css('.startlist_v4 a[href*="rider"]').filter_map do |rider|
    raw_name = rider.text.strip
    parse_name(raw_name) if raw_name.length > 3
  end
end

def post_startlist(pcs_name, riders)
  uri = URI("#{APP_URL}/api/startlists")
  request = Net::HTTP::Put.new(uri, {
    'Content-Type' => 'application/json',
    'Authorization' => "Bearer #{API_KEY}"
  })
  request.body = { pcs_name: pcs_name, riders: riders }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  puts "    -> #{response.code}: #{response.body}"
  response
end

# Fetch the list of upcoming races from the app API
def fetch_races
  uri = URI("#{APP_URL}/api/startlists")
  request = Net::HTTP::Get.new(uri, {
    'Authorization' => "Bearer #{API_KEY}"
  })

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
  end

  unless response.is_a?(Net::HTTPSuccess)
    puts "Failed to fetch races: #{response.code} #{response.body}"
    exit 1
  end

  JSON.parse(response.body)['races']
end

pcs_names = fetch_races
puts "Scraping #{pcs_names.size} upcoming races..."

driver = build_driver
begin
  pcs_names.each_with_index do |pcs_name, index|
    riders = scrape_race(driver, pcs_name)
    puts "  Found #{riders.size} riders for #{pcs_name}"

    if riders.any?
      post_startlist(pcs_name, riders)
    else
      puts "    Skipping (no riders found)"
    end

    sleep(rand(3..6)) unless index == pcs_names.size - 1
  end
ensure
  driver.quit
end

puts 'Done!'

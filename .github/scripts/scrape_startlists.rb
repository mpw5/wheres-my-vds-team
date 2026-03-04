# frozen_string_literal: true

require 'json'
require 'net/http'
require 'nokogiri'

APP_URL = ENV.fetch('APP_URL')
API_KEY = ENV.fetch('SCRAPER_API_KEY')

CYCLINGFLASH_URL = 'https://cyclingflash.com/race'
YEAR = Time.now.year

def fetch_page(url)
  uri = URI(url)
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new(uri)
    request['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ' \
                            'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36'
    http.request(request)
  end

  return response.body if response.is_a?(Net::HTTPSuccess)

  puts "    HTTP #{response.code} for #{url}"
  nil
end

def scrape_race(pcs_name)
  url = "#{CYCLINGFLASH_URL}/#{pcs_name}-#{YEAR}/startlist"
  puts "  Fetching #{url}..."

  html = fetch_page(url)
  return [] unless html

  doc = Nokogiri::HTML(html)

  # Remove footer to avoid picking up featured rider links (e.g. Pogačar, MVDP)
  doc.css('footer').each(&:remove)

  # Rider profile links have href like /profile/rider-name-slug
  doc.css('a[href*="/profile/"]').filter_map do |link|
    href = link['href']
    next unless href&.match?(%r{/profile/[\w-]+$})

    slug = href.split('/profile/').last
    # Convert slug to "first last" format: "jasper-philipsen" -> "jasper philipsen"
    slug.tr('-', ' ')
  end.uniq
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

pcs_names.each_with_index do |pcs_name, index|
  riders = scrape_race(pcs_name)
  puts "  Found #{riders.size} riders for #{pcs_name}"

  if riders.any?
    post_startlist(pcs_name, riders)
  else
    puts "    Skipping (no riders found)"
  end

  sleep(rand(2..5)) unless index == pcs_names.size - 1
rescue StandardError => e
  puts "  ERROR scraping #{pcs_name}: #{e.message}"
end

puts 'Done!'

# frozen_string_literal: true

class Race < ApplicationRecord
  STALE_AFTER = 6.hours
  CYCLINGFLASH_URL = 'https://cyclingflash.com/race'

  scope :upcoming_races, lambda { |race_type|
    where(race_type:)
      .where(end_date: Time.zone.today..)
      .order(start_date: :asc)
      .limit(10)
  }

  def startlist
    refresh_startlist! if stale?
    scraped_startlist&.split(',') || []
  end

  def stale?
    scraped_startlist.nil? || updated_at < STALE_AFTER.ago
  end

  def refresh_startlist!
    riders = scrape_startlist
    update!(scraped_startlist: riders.join(',')) if riders.any?
  rescue StandardError => e
    Rails.logger.warn("Failed to scrape startlist for #{pcs_name}: #{e.message}")
  end

  def dates
    if end_date.eql?(start_date)
      start_date.strftime('%d/%m/%Y')
    else
      "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}"
    end
  end

  def pcs_url
    "cyclingflash.com/race/#{pcs_name}-#{Time.zone.today.year}/startlist"
  end

  private

  def scrape_startlist
    url = "#{CYCLINGFLASH_URL}/#{pcs_name}-#{Time.zone.today.year}/startlist"
    uri = URI(url)

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0 (compatible; VDS-Team/1.0)'
      http.request(request)
    end

    return [] unless response.is_a?(Net::HTTPSuccess)

    doc = Nokogiri::HTML(response.body)
    doc.css('footer').each(&:remove)

    doc.css('a[href*="/profile/"]').filter_map do |link|
      href = link['href']
      next unless href&.match?(%r{/profile/[\w-]+$})

      href.split('/profile/').last.tr('-', ' ')
    end.uniq
  end
end

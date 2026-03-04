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
    html = fetch_startlist_page
    html ? parse_startlist(html) : []
  end

  def fetch_startlist_page
    uri = URI("#{CYCLINGFLASH_URL}/#{pcs_name}-#{Time.zone.today.year}/startlist")
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(Net::HTTP::Get.new(uri))
    end
    response.is_a?(Net::HTTPSuccess) ? response.body : nil
  end

  def parse_startlist(html)
    doc = Nokogiri::HTML(html)
    doc.css('footer').each(&:remove)

    doc.css('a[href*="/profile/"]').filter_map do |link|
      href = link['href']
      next unless href&.match?(%r{/profile/[\w-]+$})

      href.split('/profile/').last.tr('-', ' ')
    end.uniq
  end
end

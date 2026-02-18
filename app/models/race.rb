# frozen_string_literal: true

class Race < ApplicationRecord
  scope :upcoming_races, lambda { |race_type|
    where(race_type:)
      .where(end_date: Time.zone.today..)
      .order(start_date: :asc)
      .limit(10)
  }

  def startlist
    refresh_startlist! if startlist_stale?
    scraped_startlist&.split(',') || []
  end

  def refresh_startlist!
    StartlistScraperService.new(self).call
  end

  def startlist_stale?
    scraped_startlist.nil? || updated_at.before?(12.hours.ago)
  end

  def dates
    if end_date.eql?(start_date)
      start_date.strftime('%d/%m/%Y')
    else
      "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}"
    end
  end

  def pcs_url
    "www.procyclingstats.com/race/#{pcs_name}/#{Time.zone.today.year}/startlist"
  end
end

# frozen_string_literal: true

class Race < ApplicationRecord
  scope :upcoming_races, lambda { |race_type|
    where(race_type:).and(Race.where('end_date >= ?', Time.zone.today)).first(10)
  }

  def startlist
    if scraped_startlist.nil? || updated_at.before?(2.hours.ago)
      update!(scraped_startlist: StartlistScraperService.new(pcs_url).call.join(','))
    end

    scraped_startlist.split(',')
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

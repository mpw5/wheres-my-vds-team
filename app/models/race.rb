# frozen_string_literal: true

class Race < ApplicationRecord
  scope :upcoming_races, lambda { |race_type|
    where(race_type:).and(Race.where('end_date >= ?', Time.zone.today)).first(10)
  }

  def startlist
    if scraped_startlist.nil? || updated_at.before?(6.hours.ago)
      update!(scraped_startlist: StartlistScraperService.new(pcs_name).call.join(','))
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
end

# frozen_string_literal: true

class Race < ApplicationRecord
  scope :upcoming_races, lambda { |race_type|
    where(race_type:).and(
      Race.where('end_date >= ?', Time.zone.today).or(
        Race.where('start_date >= ?', Time.zone.today).and(
          Race.where(end_date: nil)
        )
      )
    ).first(10)
  }

  def startlist
    if scraped_startlist.nil? || updated_at.before?(6.hours.ago)
      update!(scraped_startlist: StartlistScraperService.new(pcs_name).call.join(','))
    end

    scraped_startlist.split(',')
  end
end

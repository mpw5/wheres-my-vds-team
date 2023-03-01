# frozen_string_literal: true

class Race < ApplicationRecord
  scope :upcoming_mens_races, lambda {
    where(race_type: 'mens').and(
      Race.where('end_date >= ?', Time.zone.today).or(
        Race.where('start_date >= ?', Time.zone.today).and(
          Race.where(end_date: nil)
        )
      )
    ).first(10)
  }

  scope :upcoming_womens_races, lambda {
    where(race_type: 'womens').and(
      Race.where('end_date >= ?', Time.zone.today).or(
        Race.where('start_date >= ?', Time.zone.today).and(
          Race.where(end_date: nil)
        )
      )
    ).first(10)
  }
end

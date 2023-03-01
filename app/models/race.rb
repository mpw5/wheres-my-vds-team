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
end

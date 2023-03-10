# frozen_string_literal: true

class Team < ApplicationRecord
  scope :teams_for, lambda { |team_ds|
    where('lower(ds) = ?', team_ds&.downcase).or(where('lower(name) = ?', team_ds&.downcase))
  }

  def riders_array
    parsed_riders = []
    raw_riders = riders.split(', ').sort
    raw_riders.each do |rider|
      parsed_riders << I18n.transliterate(rider).downcase
    end
    parsed_riders
  end
end

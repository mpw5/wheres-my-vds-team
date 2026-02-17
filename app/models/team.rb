# frozen_string_literal: true

class Team < ApplicationRecord
  scope :teams_for, lambda { |team_ds|
    where('lower(ds) = ?', team_ds&.downcase).or(where('lower(name) = ?', team_ds&.downcase))
  }

  def riders_array
    return [] if riders.nil?

    riders.split(',').sort.map { |rider| I18n.transliterate(rider).downcase }
  end
end

# frozen_string_literal: true

class Team < ApplicationRecord
  scope :teams_for, lambda { |team_ds|
    term = "%#{team_ds&.downcase}%"
    where('lower(ds) LIKE ?', term).or(where('lower(name) LIKE ?', term))
  }

  def riders_array
    return [] if riders.nil?

    riders.split(',').sort.map { |rider| I18n.transliterate(rider).downcase }
  end
end

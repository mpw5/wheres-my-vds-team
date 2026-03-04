# frozen_string_literal: true

class Team < ApplicationRecord
  scope :teams_for, lambda { |team_ds|
    return none if team_ds.blank?

    term = "%#{team_ds.downcase}%"
    where('lower(ds) LIKE ?', term).or(where('lower(name) LIKE ?', term))
  }

  def riders_array
    return [] if riders.nil?

    riders.split(',').sort.map { |rider| normalise(rider) }
  end

  def matching_riders(startlist)
    return [] if riders.nil?

    normalised_startlist = startlist.map { |name| normalise(name).split }

    riders.split(',').sort.select do |rider|
      rider_words = normalise(rider).split
      normalised_startlist.any? { |sl_words| (rider_words - sl_words).empty? }
    end
  end

  private

  def normalise(name)
    I18n.transliterate(name).downcase.delete("'").tr('-', ' ').gsub(/[()]/, '').squeeze(' ').strip
  end
end

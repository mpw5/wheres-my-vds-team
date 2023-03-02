# frozen_string_literal: true

class Team < ApplicationRecord
  def riders_array
    parsed_riders = []
    raw_riders = riders.split(', ').sort
    raw_riders.each do |rider|
      parsed_riders << I18n.transliterate(rider).downcase
    end
    parsed_riders
  end
end

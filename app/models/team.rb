# frozen_string_literal: true

class Team < ApplicationRecord
  def riders_array
    riders.split(', ').sort.map(&:downcase)
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :team do
    team_type { 'male' }
    name { Faker::Sports::Football.team }
    ds { Faker::Name.name }
    riders { "#{Faker::Name.name}, #{Faker::Name.name}" }
  end
end

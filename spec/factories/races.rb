# frozen_string_literal: true

FactoryBot.define do
  factory :race do
    race_type { 'mens' }
    name { Faker::Sports::Football.competition }
    pcs_name { name.downcase.parameterize }
    start_date { Time.zone.today }
    end_date { Time.zone.today }
    scraped_startlist { nil }
  end
end

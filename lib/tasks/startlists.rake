# frozen_string_literal: true

namespace :startlists do
  desc 'Refresh stale or missing startlists (single browser instance)'
  task refresh: :environment do
    races = Race.where(end_date: Time.zone.today..).order(start_date: :asc).limit(10)
    stale = races.select(&:startlist_stale?)

    puts "Found #{stale.size} stale startlist(s) out of #{races.size} upcoming race(s)"

    StartlistScraperService.new(stale).call

    puts 'Done'
  end
end

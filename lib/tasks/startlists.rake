# frozen_string_literal: true

namespace :startlists do
  desc 'Refresh stale or missing startlists (single browser instance)'
  task refresh: :environment do
    races = Race.where(end_date: Time.zone.today..).order(start_date: :asc).limit(10)
    stale = races.select(&:startlist_stale?)

    puts "Found #{stale.size} stale startlist(s) out of #{races.size} upcoming race(s)"

    stale.each { |r| puts "  - #{r.pcs_name} (#{r.pcs_url})" }

    StartlistScraperService.new(stale).call

    stale.each do |r|
      r.reload
      puts "  #{r.pcs_name}: #{r.startlist.size} riders cached"
    end

    puts 'Done'
  end
end

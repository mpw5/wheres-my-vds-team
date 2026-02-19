# frozen_string_literal: true

namespace :startlists do
  desc 'Run the scraper script locally against the Rails server'
  task refresh: :environment do
    app_url = ENV.fetch('APP_URL', 'http://localhost:3003')
    api_key = ENV.fetch('SCRAPER_API_KEY') do
      Rails.application.credentials.scraper_api_key ||
        abort('Set SCRAPER_API_KEY env var or add scraper_api_key to credentials')
    end

    script = Rails.root.join('.github/scripts/scrape_startlists.rb')
    abort("Scraper script not found at #{script}") unless script.exist?

    puts "Scraping startlists and posting to #{app_url}..."
    Bundler.with_unbundled_env do
      system({ 'APP_URL' => app_url, 'SCRAPER_API_KEY' => api_key }, "ruby #{script}") || abort('Scraper failed')
    end
  end
end

source 'https://rubygems.org'
git_source(:github) { |repo| 'https://github.com/#{repo}.git' }

ruby '3.4.1'

gem 'bootsnap', require: false
gem 'csv'
gem 'importmap-rails'
gem 'jbuilder'
gem 'puma', '~> 6.6'
gem 'rails', '~> 8.0.0'
gem 'redis', '~> 5.4'
gem 'simplecov', require: false
gem 'sprockets-rails'
gem 'sqlite3', '~> 2.7'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'tzinfo-data', platforms: %i[ mingw mswin x64_mingw jruby ]

group :development, :test do
  gem 'debug', platforms: %i[ mri mingw x64_mingw ]
  gem 'brakeman'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry'
  gem 'rspec-rails'
  gem 'rubocop'
  gem 'rubocop-capybara'
  gem 'rubocop-factory_bot'
  gem 'rubocop-rspec'
  gem 'rubocop-rspec_rails'
  gem 'rubocop-rails'
  gem 'rubocop-performance'
end

group :development do
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

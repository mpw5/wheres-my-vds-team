#!/usr/bin/env bash
# exit on error
set -o errexit

# Install dependencies
bundle install

# Install Chrome for Selenium
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
apt-get update
apt-get install -y google-chrome-stable

# Precompile assets
bundle exec rake assets:precompile
bundle exec rake assets:clean

# Setup database
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed
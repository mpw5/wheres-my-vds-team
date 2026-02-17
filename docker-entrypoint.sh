#!/bin/sh
set -e

# Run database setup
bundle exec rake db:prepare db:seed

# Start the main process
exec "$@"

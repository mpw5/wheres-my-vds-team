# Use Ruby 4.0 as base image
FROM ruby:4.0-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    nodejs \
    wget \
    gnupg \
    ca-certificates \
    curl \
    unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Chromium (easier alternative to Chrome)
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    chromium \
    chromium-driver && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Set production environment
ENV RAILS_ENV=production
ENV RACK_ENV=production

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Precompile assets with dummy secret key
RUN SECRET_KEY_BASE=dummy RAILS_ENV=production bundle exec rake assets:precompile && \
    bundle exec rake assets:clean

# Expose port
EXPOSE 3000

# Start the Rails server (database setup happens via Render's release command)
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

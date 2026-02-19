# frozen_string_literal: true

module Api
  class StartlistsController < ApplicationController
    skip_forgery_protection

    before_action :authenticate

    def index
      pcs_names = Race.upcoming_races('male').pluck(:pcs_name) +
                  Race.upcoming_races('female').pluck(:pcs_name)
      render json: { races: pcs_names }
    end

    def update
      race = Race.find_by(pcs_name: params[:pcs_name])

      unless race
        render json: { error: 'Race not found' }, status: :not_found
        return
      end

      race.update!(scraped_startlist: params[:riders].join(','))
      render json: { pcs_name: race.pcs_name, riders: params[:riders].size }, status: :ok
    end

    private

    def authenticate
      provided = request.headers['Authorization']&.delete_prefix('Bearer ')
      expected = Rails.application.credentials.scraper_api_key || ENV.fetch('SCRAPER_API_KEY', nil)

      return if ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected.to_s) && expected.present?

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end

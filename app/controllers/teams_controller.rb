# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    Rails.logger.info "DB CONFIG: #{ActiveRecord::Base.connection_db_config.configuration_hash}"
    Rails.logger.info "DB TABLES: #{ActiveRecord::Base.connection.tables.join(', ')}"
    @team_ds = permitted_params[:team_ds]&.strip
    @teams = Team.teams_for @team_ds
  end

  private

  def permitted_params
    params.permit(:team_ds)
  end
end

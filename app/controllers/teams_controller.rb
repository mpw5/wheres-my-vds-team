# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    @team_ds = permitted_params[:team_ds]&.strip
    @teams = Team.teams_for @team_ds
    @races = @teams.map(&:team_type).uniq.index_with { |type| Race.upcoming_races(type) }
  end

  private

  def permitted_params
    params.permit(:team_ds)
  end
end

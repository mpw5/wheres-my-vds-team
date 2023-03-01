# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    @team_ds = permitted_params[:team_ds]
    @teams = Team.where('lower(ds) = ?', @team_ds&.downcase).or(Team.where('lower(name) = ?', @team_ds&.downcase))
  end

  private

  def permitted_params
    params.permit(:team_ds)
  end
end

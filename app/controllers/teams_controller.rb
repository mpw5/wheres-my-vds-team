# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    @team_ds = permitted_params[:team_ds]
    @teams = Team.where(ds: @team_ds).or(Team.where(name: @team_ds))
  end

  private

  def permitted_params
    params.permit(:team_ds)
  end
end

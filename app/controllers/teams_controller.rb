# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    @team_ds = permitted_params[:team_ds]
    teams
    mens_races
    womens_races
  end

  private

  def permitted_params
    params.permit(:team_ds)
  end

  def teams
    @teams ||= Team.where(ds: @team_ds).or(Team.where(name: @team_ds))
  end

  def mens_races
    @mens_races ||= Race.where(race_type: 'mens').and(
      Race.where('end_date >= ?', Time.zone.today).or(
        Race.where('start_date >= ?', Time.zone.today).and(
          Race.where(end_date: nil)
        )
      )
    ).first(10)
  end

  def womens_races
    @womens_races ||= Race.where(race_type: 'womens').and(
      Race.where('end_date >= ?', Time.zone.today).or(
        Race.where('start_date >= ?', Time.zone.today).and(
          Race.where(end_date: nil)
        )
      )
    ).first(10)
  end
end

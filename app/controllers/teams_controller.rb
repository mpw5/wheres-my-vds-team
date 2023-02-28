# frozen_string_literal: true

class TeamsController < ApplicationController
  def index
    @team_ds = permitted_params[:team_ds]

    mens_riders
    womens_riders
    mens_races
    womens_races
  end

  private

  def permitted_params
    params.permit(:team_ds)
  end

  def mens_team
    @mens_team ||= Team.where(ds: @team_ds, team_type: 'mens').or(
      Team.where(name: @team_ds, team_type: 'mens')
    ).first
  end

  def womens_team
    @womens_team ||= Team.where(ds: @team_ds, team_type: 'womens').or(
      Team.where(name: @team_ds, team_type: 'womens')
    ).first
  end

  def mens_riders
    @mens_riders ||= mens_team&.riders&.split(', ')&.sort&.map(&:downcase)
  end

  def womens_riders
    @womens_riders ||= womens_team&.riders&.split(', ')&.sort&.map(&:downcase)
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

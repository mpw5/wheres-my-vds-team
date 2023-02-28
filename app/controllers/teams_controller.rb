class TeamsController < ApplicationController
  def index
    @team_ds = permitted_params[:team_ds]

    @mens_team = Team.where(ds: @team_ds, team_type: 'mens').or(
      Team.where(name: @team_ds, team_type: 'mens')
    ).first
    @womens_team = Team.where(ds: @team_ds, team_type: 'womens').or(
      Team.where(name: @team_ds, team_type: 'womens')
    ).first

    @mens_riders = @mens_team&.riders&.split(', ')&.sort&.map(&:downcase)
    @womens_riders = @womens_team&.riders&.split(', ')&.sort&.map(&:downcase)

    @mens_races = Race.where(race_type: 'mens').and(
      Race.where('end_date >= ?', Time.zone.today).or(
        Race.where('start_date >= ?', Time.zone.today).and(
          Race.where(end_date: nil)
        )
      )
    ).first(10)

    @womens_races = Race.where(race_type: 'womens').and(
      Race.where('end_date >= ?', Time.zone.today).or(
        Race.where('start_date >= ?', Time.zone.today).and(
          Race.where(end_date: nil)
        )
      )
    ).first(10)
  end

  private

  def permitted_params
    params.permit(:team_ds)
  end
end

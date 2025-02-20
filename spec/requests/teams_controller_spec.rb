# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamsController do
  subject(:get_teams) { get('/', params:) }

  let(:team) { create(:team) }
  let(:params) { {} }

  before { get_teams }

  context 'with no team_ds param' do
    it { expect(response).to have_http_status(:ok) }
    it { expect(response.body).to include "<h1>Where's my <a href=\"https://www.reddit.com/r/PodiumCafe2/\">Podium Cafe v2</a>" }
    it { expect(response.body).not_to include '<div class="results">' }
  end

  context 'with a team_ds param' do
    let(:params) { { team_ds: team.name } }

    it { expect(response).to have_http_status(:ok) }
    it { expect(response.body).to include "<h1>Where's my <a href=\"https://www.reddit.com/r/PodiumCafe2/\">Podium Cafe v2</a>" }
    it { expect(response.body).to include "<div class='results'>" }
  end
end

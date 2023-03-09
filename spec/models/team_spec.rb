# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team do
  subject(:team) { create(:team, riders: 'Rider One, Rider Twó, Rider Three') }

  describe 'riders_array' do
    it { expect(team.riders_array).to eq ['rider one', 'rider three', 'rider two'] }
  end
end

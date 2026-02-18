# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team do
  subject(:team) { create(:team, riders: 'Rider One,Rider Twó,Rider Three') }

  describe 'riders_array' do
    it { expect(team.riders_array).to eq ['rider one', 'rider three', 'rider two'] }

    context 'when riders is nil' do
      subject(:team) { create(:team, riders: nil) }

      it { expect(team.riders_array).to eq [] }
    end
  end

  describe 'teams_for' do
    let!(:team) { create(:team, name: 'The Rockets', ds: 'John Smith') }

    it 'matches full DS name' do
      expect(described_class.teams_for('John Smith')).to include team
    end

    it 'matches partial DS name' do
      expect(described_class.teams_for('john')).to include team
    end

    it 'matches partial team name' do
      expect(described_class.teams_for('rocket')).to include team
    end

    it 'is case insensitive' do
      expect(described_class.teams_for('JOHN')).to include team
    end

    it 'does not match unrelated terms' do
      expect(described_class.teams_for('batman')).not_to include team
    end
  end
end

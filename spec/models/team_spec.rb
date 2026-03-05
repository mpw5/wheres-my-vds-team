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

    context 'when riders have apostrophes, hyphens or extra spaces' do
      subject(:team) { create(:team, riders: "Ben O'Connor,Aurélien Paret-Peintre,Mihajlo  Stolić") }

      it 'normalises names to match scraper output' do
        expect(team.riders_array).to eq ['aurelien paret peintre', 'ben oconnor', 'mihajlo stolic']
      end
    end
  end

  describe 'matching_riders' do
    subject(:team) { create(:team, riders: 'Pello Bilbao,Tadej Pogačar,Kasia Niewiadoma') }

    it 'matches exact names' do
      startlist = ['pello bilbao', 'tadej pogacar']
      expect(team.matching_riders(startlist)).to eq ['Pello Bilbao', 'Tadej Pogačar']
    end

    it 'matches when startlist has additional name parts' do
      startlist = ['pello bilbao lopez de armentia', 'katarzyna niewiadoma']
      expect(team.matching_riders(startlist)).to eq ['Pello Bilbao']
    end

    it 'returns original cased names from seed data' do
      startlist = ['tadej pogacar']
      expect(team.matching_riders(startlist)).to eq ['Tadej Pogačar']
    end

    it 'returns empty array when no matches' do
      expect(team.matching_riders(['wout van aert'])).to eq []
    end

    it 'returns empty array when riders is nil' do
      team = create(:team, riders: nil)
      expect(team.matching_riders(['anyone'])).to eq []
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

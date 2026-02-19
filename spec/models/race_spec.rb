# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Race do
  subject!(:race) { create(:race, start_date:, end_date:) }

  let(:start_date) { Date.new(2023, 3, 9) }
  let(:end_date) { Date.new(2023, 3, 9) }

  describe 'upcoming_races' do
    let(:start_date) { Time.zone.today }
    let(:end_date) { Time.zone.today }
    let!(:another_race) { create(:race, start_date: Time.zone.today + 1, end_date: Time.zone.today + 7) }
    let!(:yet_another_race) { create(:race, start_date: Time.zone.today - 1, end_date: Time.zone.today - 1) }

    it { expect(described_class.upcoming_races('male')).to eq [race, another_race] }
    it { expect(described_class.upcoming_races('male')).not_to include yet_another_race }
  end

  describe 'startlist' do
    context 'when no startlist has been scraped' do
      it { expect(race.startlist).to eq [] }
    end

    context 'when a startlist is cached' do
      before { race.update!(scraped_startlist: 'rider_1,rider_2') }

      it { expect(race.startlist).to eq %w[rider_1 rider_2] }
    end
  end

  describe 'dates' do
    context 'when it is a one-day race' do
      it { expect(race.dates).to eq '09/03/2023' }
    end

    context 'when it is a stage race' do
      let(:end_date) { Date.new(2023, 3, 10) }

      it { expect(race.dates).to eq '09/03/2023 - 10/03/2023' }
    end
  end

  describe 'pcs_url' do
    it { expect(race.pcs_url).to eq "www.procyclingstats.com/race/#{race.pcs_name}/#{Time.zone.today.year}/startlist" }
  end
end

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
    let(:startlist_scraper_service) { instance_double StartlistScraperService }

    before do
      allow(StartlistScraperService).to receive(:new).and_return(startlist_scraper_service)
      allow(startlist_scraper_service).to receive(:call).and_return(%w[rider_1 rider_2])
    end

    it { expect(race.startlist).to eq %w[rider_1 rider_2] }

    context 'when the startlist has already been scraped' do
      before { race.update!(scraped_startlist: 'rider_1,rider_2') }

      it { expect(StartlistScraperService).not_to have_received(:new) }
      it { expect(race.startlist).to eq %w[rider_1 rider_2] }
    end

    context 'when the cached startlist is stale' do
      before do
        race.update!(scraped_startlist: 'old_rider', updated_at: 13.hours.ago)
      end

      it 're-scrapes the startlist' do
        race.startlist
        expect(StartlistScraperService).to have_received(:new)
      end
    end

    context 'when the scraper raises an error' do
      before do
        allow(startlist_scraper_service).to receive(:call).and_raise(StandardError, 'connection failed')
      end

      it 'returns an empty array' do
        expect(race.startlist).to eq []
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        race.startlist
        expect(Rails.logger).to have_received(:error).with(/connection failed/)
      end
    end

    context 'when the scraper fails but a cached startlist exists' do
      before do
        race.update!(scraped_startlist: 'cached_rider', updated_at: 13.hours.ago)
        allow(startlist_scraper_service).to receive(:call).and_raise(StandardError, 'timeout')
      end

      it 'returns the cached startlist' do
        expect(race.startlist).to eq %w[cached_rider]
      end
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

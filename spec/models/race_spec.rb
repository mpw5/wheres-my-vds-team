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
    let(:startlist_scraper_service) { instance_double(StartlistScraperService, call: nil) }

    before do
      allow(StartlistScraperService).to receive(:new).with(race).and_return(startlist_scraper_service)
    end

    context 'when no startlist has been scraped' do
      it 'triggers a refresh' do
        race.startlist
        expect(startlist_scraper_service).to have_received(:call)
      end
    end

    context 'when a fresh startlist is cached' do
      before { race.update!(scraped_startlist: 'rider_1,rider_2') }

      it { expect(race.startlist).to eq %w[rider_1 rider_2] }

      it 'does not trigger a refresh' do
        race.startlist
        expect(startlist_scraper_service).not_to have_received(:call)
      end
    end

    context 'when the cached startlist is stale' do
      before { race.update!(scraped_startlist: 'old_rider', updated_at: 13.hours.ago) }

      it 'triggers a refresh' do
        race.startlist
        expect(startlist_scraper_service).to have_received(:call)
      end
    end
  end

  describe 'refresh_startlist!' do
    let(:startlist_scraper_service) { instance_double(StartlistScraperService, call: nil) }

    before do
      allow(StartlistScraperService).to receive(:new).with(race).and_return(startlist_scraper_service)
    end

    it 'delegates to StartlistScraperService' do
      race.refresh_startlist!
      expect(startlist_scraper_service).to have_received(:call)
    end
  end

  describe 'startlist_stale?' do
    context 'when no startlist has been scraped' do
      it { expect(race).to be_startlist_stale }
    end

    context 'when the startlist was recently scraped' do
      before { race.update!(scraped_startlist: 'rider_1', updated_at: 1.hour.ago) }

      it { expect(race).not_to be_startlist_stale }
    end

    context 'when the startlist was scraped more than 12 hours ago' do
      before { race.update!(scraped_startlist: 'rider_1', updated_at: 13.hours.ago) }

      it { expect(race).to be_startlist_stale }
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

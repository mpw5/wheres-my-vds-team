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

  describe 'stale?' do
    context 'when no startlist has been scraped' do
      it { expect(race).to be_stale }
    end

    context 'when the startlist was scraped recently' do
      before { race.update!(scraped_startlist: 'rider_1,rider_2') }

      it { expect(race).not_to be_stale }
    end

    context 'when the startlist was scraped over 12 hours ago' do
      before do
        race.update!(scraped_startlist: 'rider_1,rider_2')
        race.update_column(:updated_at, 13.hours.ago)
      end

      it { expect(race).to be_stale }
    end
  end

  describe 'startlist' do
    before { allow(race).to receive(:refresh_startlist!) }

    context 'when no startlist has been scraped' do
      it 'refreshes the startlist' do
        race.startlist
        expect(race).to have_received(:refresh_startlist!)
      end

      it { expect(race.startlist).to eq [] }
    end

    context 'when a fresh startlist is cached' do
      before { race.update!(scraped_startlist: 'rider_1,rider_2') }

      it 'does not refresh the startlist' do
        race.startlist
        expect(race).not_to have_received(:refresh_startlist!)
      end

      it { expect(race.startlist).to eq %w[rider_1 rider_2] }
    end
  end

  describe 'refresh_startlist!' do
    let(:html) do
      <<~HTML
        <html><body>
          <a href="/profile/tadej-pogacar">Tadej Pogačar</a>
          <a href="/profile/jonas-vingegaard">Jonas Vingegaard</a>
          <footer><a href="/profile/someone-else">Someone Else</a></footer>
        </body></html>
      HTML
    end

    before do
      response = instance_double(Net::HTTPOK, body: html)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(Net::HTTP).to receive(:start).and_return(response)
    end

    it 'scrapes and stores the startlist' do
      race.refresh_startlist!
      expect(race.reload.scraped_startlist).to eq 'tadej pogacar,jonas vingegaard'
    end

    it 'excludes footer links' do
      race.refresh_startlist!
      expect(race.reload.scraped_startlist).not_to include('someone else')
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
    it { expect(race.pcs_url).to eq "cyclingflash.com/race/#{race.pcs_name}-#{Time.zone.today.year}/startlist" }
  end
end

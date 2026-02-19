# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Startlists' do
  let!(:race) { create(:race, pcs_name: 'tour-de-france') }
  let(:api_key) { 'test-scraper-key' }
  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{api_key}"
    }
  end
  let(:riders) { %w[tadej pogacar jonas vingegaard] }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('SCRAPER_API_KEY', nil).and_return(api_key)
  end

  describe 'GET /api/startlists' do
    before do
      create(:race, race_type: 'male', pcs_name: 'paris-roubaix',
                    start_date: Time.zone.today, end_date: Time.zone.today)
      create(:race, race_type: 'female', pcs_name: 'paris-roubaix-femmes',
                    start_date: Time.zone.today, end_date: Time.zone.today)
      create(:race, pcs_name: 'old-race', start_date: 1.week.ago, end_date: 1.week.ago)
      get '/api/startlists', headers: headers
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(response.parsed_body['races']).to include('paris-roubaix', 'paris-roubaix-femmes') }
    it { expect(response.parsed_body['races']).not_to include('old-race') }
  end

  describe 'PUT /api/startlists' do
    context 'with valid auth and known race' do
      before do
        put '/api/startlists',
            params: { pcs_name: 'tour-de-france', riders: }.to_json,
            headers: headers
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(response.parsed_body).to include('pcs_name' => 'tour-de-france', 'riders' => 4) }
      it { expect(race.reload.scraped_startlist).to eq 'tadej,pogacar,jonas,vingegaard' }
    end

    context 'with unknown race' do
      before do
        put '/api/startlists',
            params: { pcs_name: 'unknown-race', riders: }.to_json,
            headers: headers
      end

      it { expect(response).to have_http_status(:not_found) }
      it { expect(response.parsed_body).to include('error' => 'Race not found') }
    end

    context 'without auth header' do
      it 'returns unauthorized' do
        put '/api/startlists',
            params: { pcs_name: 'tour-de-france', riders: }.to_json,
            headers: { 'Content-Type' => 'application/json' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with wrong api key' do
      it 'returns unauthorized' do
        put '/api/startlists',
            params: { pcs_name: 'tour-de-france', riders: }.to_json,
            headers: { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer wrong-key' }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end

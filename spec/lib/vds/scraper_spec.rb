# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Vds::Scraper do
  # rubocop:disable RSpec/VerifiedDoubles
  let(:client) { double('GraphQlClient') }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:csv) { instance_double(CSV) }

  before do
    stub_const('Vds::GraphQlClient::Client', client)
    allow(client).to receive(:parse)
    allow(CSV).to receive(:open).and_yield(csv)
    allow(csv).to receive(:<<)
    allow(Time.zone).to receive(:today).and_return(Date.new(2026, 1, 1))
  end

  describe '.run_query' do
    it 'calls the GraphQL client with correct variables' do
      allow(client).to receive(:query).and_return(double(errors: nil))
      described_class.run_query(:query, 'MALE')
      expect(client).to have_received(:query).with(anything, variables: hash_including(year: 2026, gender: 'MALE'))
    end

    it 'raises if there are errors' do
      allow(client).to receive(:query).and_return(double(errors: { foo: 'bar' }))
      expect do
        described_class.run_query(:query, 'MALE')
      end.to raise_error(/foo/)
    end
  end

  describe '.populate_teams_csv' do
    let(:first_page) do
      double(
        data: double(
          teams: double(
            nodes: [
              double(to_h: { 'locked' => true, 'manager' => { 'displayName' => 'A' }, 'name' => 'Team1',
                             'riders' => { 'nodes' => [{ 'rider' => { 'displayName' => 'R1' } }] } }),
              double(to_h: { 'locked' => false }) # should be skipped
            ],
            page_info: double(has_next_page: true, end_cursor: 'abc')
          )
        ),
        errors: nil
      )
    end
    let(:second_page) do
      double(
        data: double(
          teams: double(
            nodes: [
              double(to_h: { 'locked' => true, 'manager' => { 'displayName' => 'B' }, 'name' => 'Team2',
                             'riders' => { 'nodes' => [{ 'rider' => { 'displayName' => 'R2' } }] } })
            ],
            page_info: double(has_next_page: false, end_cursor: nil)
          )
        ),
        errors: nil
      )
    end

    before do
      allow(client).to receive(:query).and_return(first_page, second_page)
      described_class.populate_teams_csv(gender: 'MALE')
    end

    it 'writes the first page of teams to CSV' do
      expect(csv).to have_received(:<<).with(%w[male A Team1 R1])
    end

    it 'writes the second page of teams to CSV' do
      expect(csv).to have_received(:<<).with(%w[male B Team2 R2])
    end
  end

  describe '.populate_races_csv' do
    let(:races_response) do
      double(
        data: double(
          races: double(
            nodes: [
              double(to_h: { 'race' => { 'name' => 'Race1' }, 'startDate' => '2026-01-01', 'stageCount' => 3 })
            ]
          )
        ),
        errors: nil
      )
    end

    it 'writes races to CSV' do
      allow(client).to receive(:query).and_return(races_response)
      described_class.populate_races_csv(gender: 'MALE')
      expect(csv).to have_received(:<<).with(['male', 'Race1', 'race1', '2026-01-01', 3])
    end
  end

  describe '.populate_riders_csv' do
    let(:riders_response) do
      double(
        data: double(
          riders: double(
            nodes: [
              double(to_h: {
                       'displayName' => 'Rider1',
                       'nationality' => 'GBR',
                       'season' => {
                         'team' => 'Team1',
                         'cost' => 100,
                         'previousYearCost' => 90,
                         'previousYearScore' => 200
                       }
                     })
            ]
          )
        ),
        errors: nil
      )
    end

    it 'writes riders to CSV' do
      allow(client).to receive(:query).and_return(riders_response)
      described_class.populate_riders_csv(gender: 'MALE')
      expect(csv).to have_received(:<<).with(['male', 'Rider1', 'GBR', 'Team1', 100, 90, 200])
    end
  end
end

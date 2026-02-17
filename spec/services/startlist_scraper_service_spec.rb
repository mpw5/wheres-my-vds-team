# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StartlistScraperService do
  subject(:scraper) { described_class.new('www.test.com/race/milano-sanremo/2023/startlist') }

  describe 'parse_name' do
    it { expect(scraper.parse_name('LUDWIG Cecilie Uttrup')).to eq 'cecilie uttrup ludwig' }
    it { expect(scraper.parse_name('GAUDU David')).to eq 'david gaudu' }
    it { expect(scraper.parse_name('VAN AERT Wout')).to eq 'wout van aert' }
    it { expect(scraper.parse_name('VAN DER POEL Mathieu')).to eq 'mathieu van der poel' }
    it { expect(scraper.parse_name('POGACAR Tadej')).to eq 'tadej pogacar' }
  end
end

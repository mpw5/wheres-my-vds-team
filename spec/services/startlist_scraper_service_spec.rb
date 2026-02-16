# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StartlistScraperService do
  subject(:scraper) { described_class.new(fake_url) }

  let(:fake_url) { 'www.test.com/race/milano-sanremo/2023/startlist' }

  let(:fake_html) do
    Nokogiri::HTML('<ul class="startlist_v4"><li><div class="ridersCont"><ul><li class=""><a href="rider/mathieu-van-der-poel"><span class="">VAN DER POEL Mathieu</span></a></li></ul></div></li><li><div class="ridersCont"><ul><li class><a href="rider/jasper-philipsen"><span class="">PHILIPSEN Jasper</span></a></li></ul></div></li></ul>')
  end

  before do
    allow(URI).to receive(:open).with("https://#{fake_url}", { 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36' })
    allow(Nokogiri::HTML::Document).to receive(:parse).and_return(fake_html)
  end

  xdescribe 'call' do
    it { expect(scraper.call).to eq(['mathieu van der poel', 'jasper philipsen']) }
  end

  describe 'parse_name' do
    it { expect(scraper.parse_name('LUDWIG Cecilie Uttrup')).to eq 'cecilie uttrup ludwig' }
    it { expect(scraper.parse_name('GAUDU David')).to eq 'david gaudu' }
    it { expect(scraper.parse_name('VAN AERT Wout')).to eq 'wout van aert' }
  end
end

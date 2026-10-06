# frozen_string_literal: true

require 'rails_helper'

describe BingSearch do
  describe '::provider_name' do
    it 'must return search provider name as a symbol' do
      expect(BingSearch.provider_name.class).to be Symbol
    end
  end

  describe '::map_data' do
    it 'returns an empty array when the page has no results' do
      expect(BingSearch.map_data(Nokogiri::HTML('<html><body></body></html>'))).to be_empty
    end

    it 'maps bing results to the expected format' do
      data = BingSearch.map_data(Nokogiri::HTML(SearchResponseHelpers::BING_OK))

      expect(data).to eq(
        [{ title: 'Omni - a metasearch engine', link: 'https://example.org/omni' }]
      )
    end

    it 'collects every result on the page' do
      html = <<~HTML
        <html><body>
          <li class="b_algo"><h2><a href="https://example.org/a">A</a></h2></li>
          <li class="b_algo"><h2><a href="https://example.org/b">B</a></h2></li>
        </body></html>
      HTML

      expect(BingSearch.map_data(Nokogiri::HTML(html)).size).to eq(2)
    end
  end

  describe '.call' do
    it 'returns the provider name and a mapped payload' do
      stub_provider(/bing\.com/, body: SearchResponseHelpers::BING_OK)

      result = BingSearch.call('test')

      expect(result[:provider]).to eq(:bing)
      expect(result[:status]).to eq(:ok)
      expect(result[:data].first[:link]).to eq('https://example.org/omni')
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe GoogleSearch do
  describe '::provider_name' do
    it 'must return search provider name as a symbol' do
      expect(GoogleSearch.provider_name.class).to be Symbol
    end
  end

  describe '::map_data' do
    it 'returns an empty array when the response has no items' do
      expect(GoogleSearch.map_data({})).to eq([])
    end

    it 'returns an empty array when items is nil' do
      expect(GoogleSearch.map_data('items' => nil)).to eq([])
    end

    it 'maps google results to the expected format' do
      data = GoogleSearch.map_data(SearchResponseHelpers::GOOGLE_OK)

      expect(data).to eq(
        [
          { title: 'Omnisearch', link: 'https://github.com/zarmeza/omnisearch-rails' },
          { title: 'Omni - a metasearch engine', link: 'https://example.org/omni' }
        ]
      )
    end

    it 'tolerates an item missing a title' do
      data = GoogleSearch.map_data('items' => [{ 'link' => 'https://example.org/x' }])

      expect(data).to eq([{ title: nil, link: 'https://example.org/x' }])
    end
  end

  describe '.call' do
    before do
      allow(Rails.application.config_for(:services_credentials)[:google])
        .to receive(:[]).and_call_original
    end

    it 'returns the provider name and a mapped payload' do
      stub_provider(/customsearch/, body: SearchResponseHelpers::GOOGLE_OK.to_json)

      result = GoogleSearch.call('test')

      expect(result[:provider]).to eq(:google)
      expect(result[:status]).to eq(:ok)
      expect(result[:data].first[:link]).to eq('https://github.com/zarmeza/omnisearch-rails')
    end
  end
end

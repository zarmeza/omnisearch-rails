require "rails_helper"

describe Search, type: :model do
  describe '#engine' do
    it 'validates inclusion in supported values' do
      s = Search.new
      s.valid?
      expect(s.errors.has_key? :engine).to be true

      s.engine = 'unsupported'
      s.valid?
      expect(s.errors.has_key? :engine).to be true

      Search::ENGINE_OPTIONS.each do |engine_option|
        s.engine = engine_option
        s.valid?
        expect(s.errors.has_key? :engine).to be false
      end
    end
  end

  describe '#text' do
    it 'validates presence' do
      s = Search.new
      s.valid?
      expect(s.errors.has_key? :text).to be true
    end
  end

  describe '#results' do
    # `before`, not `before(:all)`: rails_helper stubs Redis.new with a
    # MockRedis in a before(:each), so under before(:all) that stub does not
    # exist yet and the real client tries to connect to 127.0.0.1:6379.
    before do
      @results = Search.new(engine: 'both', text: 'test').results
    end

    it 'agreggates results into a single array with the expected keys' do
      @results[:results].each do |result|
        expect(result.keys).to match_array([:provider, :title, :link])
      end
    end
  end
end

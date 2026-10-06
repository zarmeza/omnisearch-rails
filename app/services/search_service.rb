# app/services/search_service.rb

class SearchService
  def initialize(url, options = {})
    redis_url = Rails.application.config_for(:redis)['url']

    @url = url
    @uri = URI(url)
    @store = SearchCache.build(url: redis_url)
    @options = options
  end

  def self.map_data(data)
    raise NotImplementedError
  end

  def self.provider_name
    raise NotImplementedError
  end

  def self.parse_response(response_body)
    raise NotImplementedError
  end

  def self.call(*args, &block)
    new(*args, &block).call
  end

  def call
    response = perform_request
    {
      provider: self.class.provider_name,
      status: response[:status],
      error_message: response[:error_message],
      data: self.class.map_data(response[:data] || {})
    }
  end

  def perform_request
    cached = safe_cache_get
    return { status: :ok, data: self.class.parse_response(cached) } if cached

    begin
      response = HTTParty.get(@url, headers: @options[:headers])

      case response.code
      when 200
        parsed_response = self.class.parse_response(response.body)
        @store.set(@url, response.body, SearchCache::TTL)
        { status: :ok, data: parsed_response }
      else
        { status: :error, error_message: response.message }
      end
    rescue HTTParty::Error => e
      { status: :error, error_message: e.message }
    end
  end

  private

  # A cache read that cannot fail the request.
  #
  # SearchCache swallows Redis errors, so this is belt-and-braces for any store
  # that does not: the cost of an uncached search is one upstream request, while
  # the cost of raising here is a 500 for the caller. Never cache the miss.
  def safe_cache_get
    @store.get(@url)
  rescue StandardError => e
    Rails.logger.warn("[SearchService] cache read failed (#{e.class}), continuing uncached: #{e.message}")
    nil
  end
end

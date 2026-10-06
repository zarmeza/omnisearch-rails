# app/services/search_service.rb

class SearchService
  def initialize(url, options = {})
    @url = url
    @uri = URI(url)
    @store = SearchCache.new
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

  # The public shape of a provider result.
  #
  # `error_messages` is plural and always an array, even though there is only
  # ever one message from one provider call. Two reasons:
  #
  # - `Search.status_by_provider` builds one entry per provider and forwards this
  #   hash into the API response, so a client sees an array of messages per
  #   provider and never has to special-case the single-message case.
  # - A provider can start reporting several failure reasons (rate limit, bad
  #   credentials, quota) and the response shape does not have to change.
  #
  # The internal `perform_request` hash stays singular: it really does hold one
  # message. The widening happens here, at the boundary, so the normalization
  # lives in exactly one place.
  def call
    response = perform_request
    {
      provider: self.class.provider_name,
      status: response[:status],
      error_messages: Array(response[:error_message]).compact,
      data: self.class.map_data(response[:data] || {})
    }
  end

  def perform_request
    cached = @store.get(@url)
    return { status: :ok, data: self.class.parse_response(cached) } if cached

    begin
      response = HTTParty.get(@url, headers: @options[:headers])

      case response.code
      when 200
        parsed_response = self.class.parse_response(response.body)
        @store.set(@url, response.body)
        { status: :ok, data: parsed_response }
      else
        { status: :error, error_message: response.message }
      end
    rescue HTTParty::Error => e
      { status: :error, error_message: e.message }
    end
  end
end

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

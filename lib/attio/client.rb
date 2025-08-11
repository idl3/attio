module Attio
  # The main client class for interacting with the Attio API.
  # 
  # This class provides access to all Attio API resources and handles
  # authentication, connection management, and request routing.
  # 
  # @example Basic client creation
  #   client = Attio::Client.new(api_key: 'your-api-key')
  # 
  # @example Custom timeout
  #   client = Attio::Client.new(api_key: 'your-api-key', timeout: 60)
  # 
  # @author Ernest Sim
  # @since 1.0.0
  class Client
    # The base URL for the Attio API v2
    API_BASE_URL = "https://api.attio.com/v2".freeze
    
    # Default request timeout in seconds
    DEFAULT_TIMEOUT = 30

    # @return [String] The API key used for authentication
    attr_reader :api_key
    
    # @return [Integer] The request timeout in seconds
    attr_reader :timeout

    # Initialize a new Attio API client.
    # 
    # @param api_key [String] Your Attio API key (required)
    # @param timeout [Integer] Request timeout in seconds (default: 30)
    # @raise [ArgumentError] if api_key is nil or empty
    # 
    # @example
    #   client = Attio::Client.new(api_key: 'sk-...your-key...')
    def initialize(api_key:, timeout: DEFAULT_TIMEOUT)
      raise ArgumentError, "API key is required" if api_key.nil? || api_key.empty?
      
      @api_key = api_key
      @timeout = timeout
    end

    # Returns the HTTP connection instance for making API requests.
    # 
    # This method creates and configures the HTTP client with proper
    # authentication headers and settings. The connection is cached
    # for subsequent requests.
    # 
    # @return [HttpClient] The configured HTTP client instance
    # @api private
    def connection
      @connection ||= HttpClient.new(
        base_url: API_BASE_URL,
        headers: {
          "Authorization" => "Bearer #{api_key}",
          "Accept" => "application/json",
          "Content-Type" => "application/json",
          "User-Agent" => "Attio Ruby Client/#{VERSION}"
        },
        timeout: timeout
      )
    end

    # Access to the Records API resource.
    # 
    # @return [Resources::Records] Records resource instance
    # @example
    #   records = client.records.list(object: 'people')
    def records
      @records ||= Resources::Records.new(self)
    end

    # Access to the Objects API resource.
    # 
    # @return [Resources::Objects] Objects resource instance
    # @example
    #   objects = client.objects.list
    def objects
      @objects ||= Resources::Objects.new(self)
    end

    # Access to the Lists API resource.
    # 
    # @return [Resources::Lists] Lists resource instance
    # @example
    #   lists = client.lists.list
    def lists
      @lists ||= Resources::Lists.new(self)
    end

    # Access to the Workspaces API resource.
    # 
    # @return [Resources::Workspaces] Workspaces resource instance
    # @example
    #   workspaces = client.workspaces.list
    def workspaces
      @workspaces ||= Resources::Workspaces.new(self)
    end

    # Access to the Attributes API resource.
    # 
    # @return [Resources::Attributes] Attributes resource instance
    # @example
    #   attributes = client.attributes.list
    def attributes
      @attributes ||= Resources::Attributes.new(self)
    end

    # Access to the Users API resource.
    # 
    # @return [Resources::Users] Users resource instance
    # @example
    #   users = client.users.list
    def users
      @users ||= Resources::Users.new(self)
    end
  end
end
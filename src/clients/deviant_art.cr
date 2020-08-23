require "http/client"
require "json"

Clients::DeviantArt.configure do |settings|
  settings.client_id = ENV["DEVIANT_ART_CLIENT_ID"]
  settings.client_secret = ENV["DEVIANT_ART_CLIENT_SECRET"]
end

class Clients::DeviantArt
  API_BASE_URL   = "www.deviantart.com"
  API_TOKEN_PATH = "/oauth2/token"
  API_FEED_PATH  = "/api/v1/oauth2/feed/home"

  Habitat.create do
    setting client_id : String
    setting client_secret : String
  end

  def initialize
  end

  def fetch
    client = HTTP::Client.new(API_BASE_URL, tls: true)
    token = get_token
    params = HTTP::Params.new({"access_token" => [token]}).to_s
    response = client.get("#{API_FEED_PATH}?#{params}")
    begin
      DeviantArtResponse::Root.from_json(response.body)
    rescue e
      Log.error { e }
      raise "There was an error fetching the DeviantArt data"
    end
  end

  private def get_token
    service_token = find_or_create_service_token
    if service_token.expired?
      service_token = refreshed_token(current_token: service_token)
    end
    service_token.token
  end

  private def refreshed_token(current_token : ServiceToken)
    response = refreshed_token_response(current_token.refresh_token)
    token = response.access_token
    refresh_token = response.refresh_token
    expires_at = Time.utc.shift(seconds: response.expires_in, nanoseconds: 0)
    SaveServiceToken.update!(
      current_token,
      expires_at: expires_at,
      token: token,
      refresh_token: refresh_token
    )
  end

  private def refreshed_token_response(refresh_token : String?) : DeviantArtAuthResponse
    client = HTTP::Client.new(API_BASE_URL, tls: true)
    params = HTTP::Params.build do |query|
      query.add("client_id", settings.client_id)
      query.add("client_secret", settings.client_secret)
      query.add("grant_type", "refresh_token")
      query.add("refresh_token", refresh_token)
      query.add("mature_content", "true")
    end
    path_with_params = "#{API_TOKEN_PATH}?#{params}"
    response = client.get(path_with_params)
    begin
      DeviantArtAuthResponse.from_json(response.body)
    rescue
      Log.error { response.body }
      raise "There was an error refreshing the token"
    end
  end

  private def find_or_create_service_token
    ServiceTokenQuery.new.service("DeviantArt").first? ||
      SaveServiceToken.create!(
        service: "DeviantArt",
        token: "no-token-yet",
        expires_at: Time.utc.shift(seconds: -1, nanoseconds: 0)
      )
  end
end

class DeviantArtAuthResponse
  include JSON::Serializable

  property access_token : String
  property refresh_token : String
  property expires_in : Int32
end

module DeviantArtResponse
  class Base
    include JSON::Serializable
  end

  class Root < Base
    property items : Array(Item)
  end

  class Item < Base
    property deviations : Array(Deviation)
  end

  class Deviation < Base
    property deviationid : String
    property url : String
    property title : String
    property author : Author
    property published_time : String
    property content : Content
  end

  class Author < Base
    property username : String
  end

  class Content < Base
    property src : String
  end
end

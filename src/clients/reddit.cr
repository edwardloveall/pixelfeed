require "http/client"
require "json"

Clients::Reddit.configure do |settings|
  settings.api_id = ENV["REDDIT_API_ID"]
  settings.api_key = ENV["REDDIT_API_KEY"]
  settings.username = ENV["REDDIT_USERNAME"]
  settings.password = ENV["REDDIT_PASSWORD"]
  settings.user_agent = ENV["REDDIT_USER_AGENT"]
end

class Clients::Reddit
  getter config : SubredditConfig

  Habitat.create do
    setting api_id : String
    setting api_key : String
    setting user_agent : String
    setting username : String
    setting password : String
  end

  def initialize(@config : SubredditConfig)
  end

  def fetch
    client = HTTP::Client.new("oauth.reddit.com", tls: true)
    token = get_token
    response = client.get(
      config.to_path_and_params,
      headers: HTTP::Headers{
        "User-Agent"    => settings.user_agent,
        "Authorization" => "bearer #{token}",
      }
    )
    begin
      SubredditResponse::Root.from_json(response.body)
    rescue
      Log.error { response.body }
      raise "There was an error fetching the subreddit data"
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
    response = refreshed_token_response
    token = response.access_token
    expires_at = Time.utc.shift(seconds: response.expires_in, nanoseconds: 0)
    SaveServiceToken.update!(
      current_token,
      expires_at: expires_at,
      token: token
    )
  end

  private def refreshed_token_response
    client = HTTP::Client.new("www.reddit.com", tls: true)
    client.basic_auth(username: settings.api_id, password: settings.api_key)
    response = client.post(
      "/api/v1/access_token",
      form: {
        "grant_type" => "password",
        "username"   => settings.username,
        "password"   => settings.password,
      },
    )
    begin
      AuthResponse.from_json(response.body)
    rescue
      Log.error { response.body }
      raise "There was an error refreshing the auth token"
    end
  end

  private def find_or_create_service_token
    ServiceTokenQuery.new.service("Reddit").first? ||
      SaveServiceToken.create!(
        service: "Reddit",
        token: "no-token-yet",
        expires_at: Time.utc.shift(seconds: -1, nanoseconds: 0)
      )
  end
end

class AuthResponse
  include JSON::Serializable

  property access_token : String
  property expires_in : Int32
end

module SubredditResponse
  class Base
    include JSON::Serializable
  end

  class Root < Base
    property data : Data
  end

  class Data < Base
    property children : Array(Child)
  end

  class Child < Base
    property data : ChildData
  end

  class ChildData < Base
    property author : String
    property created : Float32
    property is_video : Bool
    property media : Media | Nil
    property name : String
    property permalink : String
    property title : String
    property url : String
  end

  class Media < Base
    property reddit_video : RedditVideo
  end

  class RedditVideo < Base
    property fallback_url : String
    property height : Int32
    property width : Int32
  end
end

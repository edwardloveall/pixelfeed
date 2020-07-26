require "http/client"

Clients::Twitter.configure do |settings|
  settings.consumer_key = ENV.fetch("TWITTER_CONSUMER_API_KEY")
  settings.consumer_secret = ENV.fetch("TWITTER_CONSUMER_API_SECRET")
  settings.access_token = ENV.fetch("TWITTER_ACCESS_TOKEN")
  settings.access_token_secret = ENV.fetch("TWITTER_ACCESS_TOKEN_SECRET")
end

class Clients::Twitter
  BASE_HOST              = "api.twitter.com"
  LIST_STATUSES_ENDPOINT = "1.1/lists/statuses.json"

  getter config : TwitterConfig

  Habitat.create do
    setting consumer_key : String
    setting consumer_secret : String
    setting access_token : String
    setting access_token_secret : String
  end

  def initialize(@config : TwitterConfig)
  end

  def fetch
    params = {
      "list_id"     => config.list_id,
      "include_rts" => config.retweets.to_s,
    }
    options = {
      "consumer_key"    => settings.consumer_key,
      "consumer_secret" => settings.consumer_secret,
      "token"           => settings.access_token,
      "token_secret"    => settings.access_token_secret,
    }
    url = "https://#{BASE_HOST}/#{LIST_STATUSES_ENDPOINT}"
    auth_header = OauthHeader.new(:get, url, params, options).to_s
    query = HTTP::Params.encode(params).to_s
    client = HTTP::Client.new(BASE_HOST, tls: true)
    uri = URI.new(path: url, query: query).to_s
    response = client.get(
      uri,
      headers: HTTP::Headers{"Authorization" => auth_header}
    )
    TwitterResponse::Root.from_json(response.body)
  end
end

module TwitterResponse
  class Base
    include JSON::Serializable
  end

  alias Root = Array(TwitterResponse::Tweet)

  class Tweet < Base
    getter created_at : String
    getter entities : Entity
    getter extended_entities : ExtendedEntity | Nil
    getter id : Int64
    getter text : String
    getter user : User
  end

  class Entity < Base
    getter hashtags : Array(Hashtag)
  end

  class Hashtag < Base
    getter text : String
  end

  class ExtendedEntity < Base
    getter media : Array(Medium)
  end

  class Medium < Base
    getter media_url_https : String
  end

  class User < Base
    getter id : Int64
    getter name : String
    getter screen_name : String
  end
end

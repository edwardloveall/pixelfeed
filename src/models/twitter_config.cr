TwitterConfig.configure do |settings|
  settings.list_id = ENV.fetch("TWITTER_LIST_ID")
end

class TwitterConfig
  getter list_id : String
  getter retweets : Bool

  Habitat.create do
    setting list_id : String
  end

  def initialize(@retweets)
    @list_id = settings.list_id
  end
end

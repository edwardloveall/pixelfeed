class Api::Twitter::Feed::Index < ApiAction
  get "/twitter/feed" do
    config = TwitterConfig.new(retweets: false)
    response = Clients::Twitter.new(config).fetch
    json Formatters::Twitter.new(response, config).feed
  end
end

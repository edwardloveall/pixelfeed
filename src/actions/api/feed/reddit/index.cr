class Api::Feed::Reddit::Index < ApiAction
  get "/reddit/feed" do
    config = SubredditConfig.new(
      subreddit: "PixelArt",
      sort: SubredditConfig::Sort::Top,
      time: SubredditConfig::TimeRange::Day
    )
    response = Clients::Reddit.new(config).fetch
    json Formatters::Reddit.new(response, config).feed
  end
end

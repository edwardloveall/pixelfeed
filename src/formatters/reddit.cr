class Formatters::Reddit
  getter response : SubredditResponse::Root
  getter config : SubredditConfig

  def initialize(@response, @config)
  end

  def feed : Feed
    Feed.new(
      feed_url: Api::Feed::Show.url,
      home_page_url: home_page_url,
      items: items,
      title: "Reddit - #{config.subreddit}",
      version: "https://jsonfeed.org/version/1",
    )
  end

  def home_page_url
    query = HTTP::Params.new({"t" => [config.time.to_s]}).to_s
    URI.new(
      scheme: "https",
      host: "reddit.com",
      path: "/r/#{config.subreddit}/#{config.sort}",
      query: query
    ).to_s
  end

  private def items : Array(FeedItem)
    response.data.children.map do |item|
      FeedItem.new(
        author: FeedItemAuthor.new(item.data.author),
        content_html: content_html(item),
        date_published: Time.unix(item.data.created.to_i),
        id: item.data.name,
        title: item.data.title,
        url: "https://reddit.com#{item.data.permalink}",
      )
    end
  end

  private def content_html(item : SubredditResponse::Child) : String
    if item.data.is_video &&
      (media = item.data.media) &&
      (media_meta = media.reddit_video)
      video_content(media_meta)
    else
      image_content(item)
    end
  end

  private def image_content(item : SubredditResponse::Child) : String
    <<-HTML.strip
      <img src="#{item.data.url}" />
    HTML
  end

  private def video_content(
    media_data : SubredditResponse::RedditVideo
  ) : String
    <<-HTML.strip
      <video autoplay loop
        width="#{media_data.width}"
        height="#{media_data.height}"
      >
        <source src="#{media_data.fallback_url}">
        Your browser does not support the video tag.
      </video>
    HTML
  end
end

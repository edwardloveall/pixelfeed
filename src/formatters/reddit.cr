class Formatters::Reddit
  alias Response = SubredditResponse::Root
  alias Child = SubredditResponse::Child
  alias Media = SubredditResponse::Media
  alias OEmbed = SubredditResponse::OEmbed
  alias RedditVideo = SubredditResponse::RedditVideo
  alias MediaMetadata = Hash(String, SubredditResponse::MediaMetadata)
  alias MediaSource = SubredditResponse::Source

  getter response : Response
  getter config : SubredditConfig

  def initialize(@response, @config)
  end

  def feed : Feed
    Feed.new(
      feed_url: Api::Feed::Reddit::Index.url,
      home_page_url: subreddit_url,
      items: items,
      title: "Reddit - #{config.subreddit}",
      version: "https://jsonfeed.org/version/1",
    )
  end

  def subreddit_url
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

  private def content_html(item : Child) : String
    if media = video_or_embed(item)
      if (video_data = media.reddit_video)
        video_content(video_data)
      elsif oembed_data = media.oembed
        oembed_content(oembed_data)
      else
        fallback_content(item)
      end
    elsif gallery_items = gallery_root(item)
      gallery_content(gallery_items)
    else
      image_content(item)
    end
  end

  private def fallback_content(item : Child) : String
    <<-HTML.strip
      <p>⚠️ Something went wrong. Here's the item:</p>
      <pre style="white-space: pre-wrap;">#{item.to_json}</pre>
    HTML
  end

  private def video_or_embed(item : Child) : Media | Nil
    item.data.media
  end

  private def image_content(item : Child) : String
    <<-HTML.strip
      <img src="#{item.data.url}" />
    HTML
  end

  private def oembed_content(oembed_data : OEmbed) : String
    HTML.unescape(oembed_data.html)
  end

  private def video_content(
    media_data : RedditVideo
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

  private def gallery_root(item : Child) : MediaMetadata | Nil
    item.data.media_metadata
  end

  private def gallery_content(gallery_items : MediaMetadata) : String
    gallery_items
      .values
      .map { |gallery_item| gallery_url(source: gallery_item.s) }
      .map { |url| %{<img src="#{url}" />} }
      .join
  end

  private def gallery_url(source : MediaSource)
    fallback = "http://s.edwardloveall.com/error-check-your-json.png"
    HTML.unescape(source.u || source.gif || fallback)
  end
end

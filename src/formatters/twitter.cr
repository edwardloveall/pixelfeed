class Formatters::Twitter
  DATE_FORMAT = "%a %b %d %H:%M:%S %z %Y"
  alias Tweet = TwitterResponse::Tweet
  alias Medium = TwitterResponse::Medium

  getter response : TwitterResponse::Root
  getter config : TwitterConfig

  def initialize(@response, @config)
  end

  def feed : Feed
    Feed.new(
      feed_url: Api::Twitter::Feed::Index.url,
      home_page_url: list_url,
      items: items,
      title: "Twitter Pixelart Feed",
      version: "https://jsonfeed.org/version/1",
    )
  end

  def list_url
    "https://twitter.com/i/#{config.list_id}"
  end

  private def items : Array(FeedItem)
    tweets = response.map do |tweet|
      next if !should_display?(tweet)
      FeedItem.new(
        author: FeedItemAuthor.new(author(tweet)),
        content_html: content_html(tweet),
        date_published: created_at(tweet),
        id: tweet.id.to_s,
        title: author(tweet),
        url: url(tweet),
      )
    end
    tweets.compact
  end

  private def author(tweet : Tweet)
    "#{tweet.user.name} (#{tweet.user.screen_name})"
  end

  private def created_at(tweet : Tweet)
    Time.parse_utc(tweet.created_at, DATE_FORMAT)
  end

  private def url(tweet : Tweet)
    "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id}"
  end

  private def content_html(tweet : Tweet) : String
    <<-HTML.strip
      <p>#{nicer_text(tweet)}</p>
      #{content(tweet)}
    HTML
  end

  private def nicer_text(tweet : Tweet)
    tweet.text.gsub("\n", "<br />")
  end

  private def content(tweet : Tweet)
    if entities = tweet.extended_entities
      entities.media.map do |medium|
        display_medium(medium)
      end.join("\n")
    else
      return ""
    end
  end

  private def display_medium(medium : Medium)
    if medium.type == "photo"
      %(<img src="#{medium.media_url_https}" />)
    elsif medium.type == "animated_gif" && (video_info = medium.video_info)
      video_info.variants.map do |variant|
        <<-HTML.strip
          <video autoplay loop>
            <source src="#{variant.url}">
            Your browser does not support the video tag.
          </video>
        HTML
      end.join("\n")
    else
      "Could not parse media content. Here's the JSON:" +
        medium.to_json
    end
  end

  private def fallback_content(tweet : Tweet) : String
    <<-HTML.strip
      <p>⚠️ Something went wrong. Here's the tweet json:</p>
      <pre style="white-space: pre-wrap;">#{tweet.to_json}</pre>
    HTML
  end

  private def should_display?(tweet : Tweet)
    tagged_pixelart?(tweet) && has_media?(tweet)
  end

  private def has_media?(tweet : Tweet)
    tweet.extended_entities
  end

  private def tagged_pixelart?(tweet : Tweet)
    tweet
      .entities
      .hashtags
      .map(&.text)
      .includes?("pixelart")
  end
end

class Formatters::DeviantArt
  alias Response = DeviantArtResponse::Root
  alias Item = DeviantArtResponse::Item
  alias Deviation = DeviantArtResponse::Deviation

  getter response : Response

  def initialize(@response)
  end

  def feed : Feed
    Feed.new(
      feed_url: Api::Feed::DeviantArt::Index.url,
      home_page_url: "https://www.deviantart.com/notifications/watch",
      items: items,
      title: "DeviantArt - Watching",
      version: "https://jsonfeed.org/version/1",
    )
  end

  private def items : Array(FeedItem)
    response.items.map do |item|
      item.deviations.map do |deviation|
        FeedItem.new(
          author: FeedItemAuthor.new(deviation.author.username),
          content_html: content_html(deviation),
          date_published: Time.unix(deviation.published_time.to_i),
          id: deviation.deviationid,
          title: deviation.title,
          url: deviation.url,
        )
      end
    end.flatten.compact
  end

  private def content_html(deviation : Deviation)
    %{<img src="#{deviation.content.src}" />}
  end
end

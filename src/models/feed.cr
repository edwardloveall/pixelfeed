struct Feed
  include JSON::Serializable

  getter feed_url : String
  getter home_page_url : String
  getter items : Array(FeedItem)
  getter title : String
  getter version : String

  def initialize(@feed_url, @home_page_url, @items, @title, @version)
  end
end

struct FeedItem
  include JSON::Serializable

  property author : FeedItemAuthor
  property content_html : String
  property date_published : Time
  property id : String
  property title : String
  property url : String

  def initialize(@author, @content_html, @date_published, @id, @title, @url)
  end
end

struct FeedItemAuthor
  include JSON::Serializable

  property name : String

  def initialize(@name)
  end
end

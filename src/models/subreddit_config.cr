class SubredditConfig
  getter subreddit : String
  getter sort : Sort
  getter time : TimeRange

  def initialize(@subreddit, @sort, @time)
  end

  enum Sort
    Hot
    New
    Rising
    Controversial
    Top
    Gilded

    def to_s
      case self
      when Hot
        ""
      when New
        "new"
      when Rising
        "rising"
      when Controversial
        "controversial"
      when Top
        "top"
      when Gilded
        "gilded"
      else
        ""
      end
    end
  end

  enum TimeRange
    Hour
    Day
    Week
    Month
    Year
    AllTime

    def to_s
      case self
      when Hour
        "hour"
      when Day
        "day"
      when Week
        "week"
      when Month
        "month"
      when Year
        "year"
      when AllTime
        "all"
      else
        "week"
      end
    end
  end

  def to_path_and_params
    query = HTTP::Params.new({"t" => [time.to_s]}).to_s
    URI.new(path: "/r/#{subreddit}/#{sort}", query: query).to_s
  end
end

class Api::Feed::DeviantArt::Index < ApiAction
  get "/deviant_art/feed" do
    response = Clients::DeviantArt.new.fetch
    json Formatters::DeviantArt.new(response).feed
  end
end

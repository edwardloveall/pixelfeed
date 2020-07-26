class Root < ApiAction
  get "/" do
    plain_text "Hello."
  end
end

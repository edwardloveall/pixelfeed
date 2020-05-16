class ServiceToken < BaseModel
  table do
    column service : String
    column token : String
    column expires_at : Time
  end

  def expired?
    expires_at < Time.utc
  end
end

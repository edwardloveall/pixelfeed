module Api::Auth::SkipRequireAuthToken
  macro included
    skip require_auth_token
  end

  def current_user : User?
    current_user?
  end
end

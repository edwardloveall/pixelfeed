abstract class ApiAction < Lucky::Action
  accepted_formats [:json]

  include Api::Auth::Helpers
  include Api::Auth::RequireAuthToken
end

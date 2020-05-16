Lucky::Server.configure do |settings|
  if Lucky::Env.production?
    settings.secret_key_base = secret_key_from_env
    settings.host = "0.0.0.0"
    settings.port = ENV["PORT"].to_i
    settings.gzip_enabled = true
  else
    settings.host = Lucky::ServerSettings.host
    settings.port = Lucky::ServerSettings.port
    settings.secret_key_base = "2HOoOuC+eg8/VwFo3H/pVQ4/84dXnpEdjYNigpRbuis="
  end

  settings.asset_host = ""
end

Lucky::ForceSSLHandler.configure do |settings|
  settings.enabled = false
end

private def secret_key_from_env
  ENV["SECRET_KEY_BASE"]? || raise_missing_secret_key_in_production
end

private def raise_missing_secret_key_in_production
  puts "Please set the SECRET_KEY_BASE environment variable. You can generate a secret key with 'lucky gen.secret_key'".colorize.red
  exit(1)
end

# https://luckyframework.org/guides/http-and-routing/http-handlers

class AppServer < Lucky::BaseAppServer
  def middleware : Array(HTTP::Handler)
    [
      Lucky::ForceSSLHandler.new,
      Lucky::HttpMethodOverrideHandler.new,
      Lucky::LogHandler.new,
      Lucky::ErrorHandler.new(action: Errors::Show),
      Lucky::RemoteIpHandler.new,
      Lucky::RouteHandler.new,
      Lucky::RouteNotFoundHandler.new,
    ] of HTTP::Handler
  end

  def protocol
    "http"
  end

  # Learn about bind_tcp: https://tinyurl.com/bind-tcp-docs
  def listen
    server.bind_tcp(host, port, reuse_port: false)
    server.listen
  end
end

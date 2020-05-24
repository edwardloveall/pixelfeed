# https://luckyframework.org/guides/getting-started/logging
require "file_utils"

if Lucky::Env.test?
  FileUtils.mkdir_p("tmp")

  backend = Log::IOBackend.new(File.new("tmp/test.log", mode: "w"))
  backend.formatter = Lucky::PrettyLogFormatter.proc
  Log.dexter.configure(:debug, backend)
elsif Lucky::Env.production?
  backend = Log::IOBackend.new
  backend.formatter = Dexter::JSONLogFormatter.proc
  Log.dexter.configure(:info, backend)
else
  backend = Log::IOBackend.new
  backend.formatter = Lucky::PrettyLogFormatter.proc
  Log.dexter.configure(:debug, backend)
end

Lucky::ContinuedPipeLog.dexter.configure(:none)
Avram::QueryLog.dexter.configure(:none)

# Skip logging static assets requests in development
Lucky::LogHandler.configure do |settings|
  if Lucky::Env.development?
    settings.skip_if = ->(context : HTTP::Server::Context) {
      context.request.method.downcase == "get" &&
      context.request.resource.starts_with?(/\/css\/|\/js\/|\/assets\/|\/favicon\.ico/)
    }
  end
end

# modified from https://github.com/watzon/easy_oauth

class Hash(K, V)
  def sort
    to_a.sort.to_h
  end

  # Returns a tuple populated with the elements at the given indexes. Invalid indexes are ignored.
  def values_at?(*indexes : K)
    indexes.map { |index| self[index]? }
  end
end

class OauthHeader
  ATTRIBUTE_KEYS = ["callback", "consumer_key", "nonce", "signature_method", "timestamp", "token", "verifier", "version"]

  IGNORED_KEYS = ["consumer_secret", "token_secret", "signature"]

  getter :method, :params, :options

  @method : String
  @uri : URI
  @params : Hash(String, String)
  @options : Hash(String, String) = {} of String => String

  def self.default_options
    {
      "nonce"            => Random.new.random_bytes(16).hexstring,
      "signature_method" => "HMAC-SHA1",
      "timestamp"        => Time.utc.to_unix.to_s,
      "version"          => "1.0",
    }
  end

  def self.escape(value)
    URI.encode_www_form(value.to_s, space_to_plus: false)
  end

  def initialize(method, url, params, oauth = {} of String => String)
    @method = method.to_s.upcase
    @uri = url.is_a?(URI) ? url : URI.parse(url)
    @uri.scheme = @uri.scheme ? @uri.scheme.not_nil!.downcase : "https"
    @uri.normalize!
    @uri.fragment = nil
    @params = params
    @options = OauthHeader.default_options.merge(oauth)
  end

  def url
    uri = @uri.dup
    uri.host = uri.host.not_nil!.downcase unless uri.host.nil?
    uri.query = nil
    uri.to_s
  end

  def to_s
    "OAuth #{normalized_attributes}"
  end

  def normalized_attributes(attrs = signed_attributes)
    attrs.sort.map { |k, v| %(#{k}="#{OauthHeader.escape(v)}") }.join(", ")
  end

  def signed_attributes(attrs = attributes)
    attrs.merge({"oauth_signature" => hmac_sha1_signature})
  end

  def hmac_sha1_signature
    Base64.encode(
      OpenSSL::HMAC.digest(:sha1, secret, signature_base)
    ).chomp.gsub(/\n/, "")
  end

  def attributes
    matching_keys, extra_keys = @options.keys.partition { |key| ATTRIBUTE_KEYS.includes?(key) }
    extra_keys -= IGNORED_KEYS
    if !!options["ignore_extra_keys"]? || extra_keys.empty?
      options.select { |key, _| matching_keys.includes?(key) }.map { |key, value| ["oauth_#{key}", value] }.to_h
    else
      raise "EasyOAuth: Found extra option keys not matching ATTRIBUTE_KEYS:\n  [other]"
    end
  end

  def secret
    options.values_at?("consumer_secret", "token_secret").map { |value|
      OauthHeader.escape(value)
    }.join("&")
  end

  def signature_base
    [method, url, normalized_params].map { |value|
      OauthHeader.escape(value)
    }.join("&")
  end

  def normalized_params
    signature_params.map { |params|
      params.map { |value|
        OauthHeader.escape(value)
      }
    }.map { |params| params.join("=") }.sort.join("&")
  end

  def signature_params
    attributes.to_a + params.to_a + url_params
  end

  def url_params
    HTTP::Params.parse(@uri.query || "")
      .reduce([] of Array(String)) { |params, (key, value)|
        params.push([key, value])
      }.sort
  end
end

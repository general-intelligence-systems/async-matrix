# frozen_string_literal: true

module EchoBot
  class Config
    attr_reader :homeserver_url
    attr_reader :domain
    attr_reader :as_token
    attr_reader :hs_token
    attr_reader :bot_mxid
    attr_reader :bind

    def initialize(data)
      hs = data.fetch("homeserver")
      as = data.fetch("appservice")
      sv = data.fetch("server", {})

      @homeserver_url = hs.fetch("url").chomp("/")
      @domain         = hs.fetch("domain")
      @as_token       = as.fetch("as_token")
      @hs_token       = as.fetch("hs_token")
      @bot_mxid       = as.fetch("bot_mxid")
      @bind           = sv.fetch("bind", "http://0.0.0.0:9292")

      validate!
    end

    def self.load(path)
      raise Matrix::Errors::NotFound.new("M_NOT_FOUND", "Config not found: #{path}") unless File.exist?(path)

      data = YAML.safe_load_file(path, permitted_classes: [Symbol])
      new(data)
    end

    private

    def validate!
      raise Matrix::Errors::BadJson.new("M_BAD_JSON", "homeserver.url is required")     if @homeserver_url.empty?
      raise Matrix::Errors::BadJson.new("M_BAD_JSON", "appservice.as_token is required") if @as_token.empty?
      raise Matrix::Errors::BadJson.new("M_BAD_JSON", "appservice.hs_token is required") if @hs_token.empty?
      raise Matrix::Errors::BadJson.new("M_BAD_JSON", "appservice.bot_mxid is required") if @bot_mxid.empty?

      if @as_token.include?("CHANGE_ME") || @hs_token.include?("CHANGE_ME")
        raise Matrix::Errors::Auth.new("M_FORBIDDEN", "Replace placeholder tokens in config before starting")
      end
    end
  end
end

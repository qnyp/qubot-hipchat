# -*- coding: utf-8 -*-
require 'json'
require 'open-uri'
require 'nokogiri'

module Qubot::Plugin

  # Public: ステータスプラグイン
  # 指定されたサービスの状況を取得して表示します。
  #
  #   @qubot status [github|heroku]
  #
  class Status
    REGEXP = /status\s+(.+)/i

    def self.register(bot)
      bot.respond(REGEXP) do |room, nick, msg, matches|
        @@logger = bot.logger
        service = matches[1].strip.downcase
        data = self.exec(service)
        bot.send(room, data[:result])
      end
    end

    def self.exec(service)
      handler = "Qubot::Plugin::Status::#{service.classify}".constantize.new
      {
        result: handler.status,
      }
    rescue NameError => e
      { result: "Unknown service name '#{service}'" }
    end
  end

  class Status::Github
    URL = 'https://status.github.com/api/last-message.json'
    attr_reader :status

    def initialize
      json = JSON.parse(open(URL).read())
      lines = []
      lines << json['status']
      lines << json['body']
      @status = lines.join("\n")
    end
  end

  class Status::Heroku
    URL = 'https://status.heroku.com/api/v3/current-status'
    attr_reader :status

    def initialize
      json = JSON.parse(open(URL).read())
      lines = []
      lines << json['status'].map { |k, v| "#{k}: #{v}" }.join(", ")
      lines << json['issues'].inspect if json['issues'].size > 0
      @status = lines.join("\n")
    end
  end

end

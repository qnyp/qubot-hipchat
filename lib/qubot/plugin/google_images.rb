# -*- coding: utf-8 -*-
require 'open-uri'
require 'uri'
require 'json'

module Qubot::Plugin

  # Public: Google画像検索プラグイン
  #
  #   @nick image me キーワード
  #   @nick image face キーワード
  #   @nick image animated キーワード
  #
  class GoogleImages
    REGEXP = /(image|img)\s+(me|face|animated)\s+(.+)/i

    def self.register(bot)
      bot.respond(REGEXP) do |room, nick, msg, matches|
        type = matches[2]
        query = matches[3]
        data = self.exec(type, query)
        bot.send(room, data[:result])
      end
    end

    def self.exec(type, query)
      url = "http://ajax.googleapis.com/ajax/services/search/images?v=1.0&rsz=8&safe=active"
      if type.downcase == 'face'
        url << "&imgtype=face"
      elsif type.downcase == 'animated'
        url << "&imgtype=animated"
      end
      url << "&q=#{URI.escape(query)}"

      response = open(url).read
      images = JSON.parse(response)
      images = images['responseData']['results']

      result = "エラー: 該当する検索結果はありません"
      if images.size > 0
        image = type.downcase == 'me' ? images.sample : images.first
        result = "#{image['unescapedUrl']}#.png"
      end

      { result: result }
    end
  end

end

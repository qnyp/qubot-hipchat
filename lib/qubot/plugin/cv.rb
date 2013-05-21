# -*- coding: utf-8 -*-
require 'open-uri'
require 'nokogiri'
require 'uri'

module Qubot::Plugin

  # Public: CVプラグイン
  # 指定された声優のWikipediaページからテレビアニメの出演作品を取得して表示します。
  #
  #   @nick cv 声優名
  #
  class Cv
    REGEXP = /(cv|cvapi)\s+(.+)/i
    WIKIPEDIA_BASE_URL = 'http://ja.wikipedia.org/wiki/'

    def self.register(bot)
      bot.respond(REGEXP) do |room, nick, msg, matches|
        @@logger = bot.logger
        keyword = matches[2]
        data = self.exec(keyword)
        bot.send(room, data[:result])
      end
    end

    def self.exec(keyword)
      url = self.wikipedia_url(keyword)
      response = open(url).read()
      html = Nokogiri::HTML(response)

      years = []  # 西暦毎の出演作品一覧の配列

      tv_anime_elements = []
      stop_element_name = 'h3'
      parent = nil
      begin
        parent = html.css("#{stop_element_name} span.mw-headline").select{ |i| i.text == 'テレビアニメ' }.first.parent
      rescue => e
        # 「平野綾」のページに対応
        stop_element_name = 'h4'
        parent = html.css("#{stop_element_name} span.mw-headline").select{ |i| i.text == 'テレビアニメ' }.first.parent
      end
      current_element = parent.next_sibling
      while current_element != nil && current_element.name != stop_element_name
        if current_element.name != 'text'
          tv_anime_elements << current_element
        end
        current_element = current_element.next_sibling
      end

      lines = []
      tv_anime_elements.each do |elem|
        tag_name = elem.name
        text = elem.text
        next if text =~ /^※太字は.+/

        case tag_name
        when 'p'  # 西暦
          # バッファに残っている内容(前年の出演作品一覧)をyears配列に追加
          years << lines.join("\n") if lines.size > 0
          # バッファを初期化して西暦を代入
          lines = []
          lines << text
        when 'ul'  # 出演作品のリスト
          elem.css('li').each do |li_elem|
            # 注釈タグ(<sup>)を削除
            li_elem.css('sup').remove()
            # 主役級にはアスタリスクを追加
            li_text = li_elem.text
            if li_elem.css('b').size > 0
              li_text = li_elem.text.gsub(/(.+)（(.+)）$/, '\1（*\2）')
            end
            lines << "  - #{li_text}"
          end
        end
      end

      # バッファに残っている内容をyears配列に追加
      years << lines.join("\n") if lines.size > 0

      result = nil
      if years.size > 0
        # years配列の内容を逆順に結合する
        result = years.reverse.join("\n")
      else
        result = "「#{keyword}」に一致する情報は見つかりませんでした: "
      end

      {
        result: result,
      }
    rescue OpenURI::HTTPError => e
      @@logger.error "Error: #{e.inspect}: #{e.backtrace.join("\n")}"
      {
        result: "エラー: #{e.message}"
      }
    end

    # Public: 指定されたページ名のWikipediaページURLを返します
    def self.wikipedia_url(page_name)
      WIKIPEDIA_BASE_URL + URI.escape(page_name)
    end
  end

end

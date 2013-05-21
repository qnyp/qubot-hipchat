# -*- coding: utf-8 -*-
require 'open-uri'
require 'nokogiri'

module Qubot::Plugin

  # Public: Wikipediaエピソード検索プラグイン
  #
  #   @nick episode Wikipediaページ名 | Wikipedia URL
  #
  class Wikipedia
    REGEXP_EPISODE = /episode\s+(.+)/i
    REGEXP_STAFF   = /staff\s+(.+)/i
    REGEXP_CAST    = /cast\s+(.+)/i

    def self.register(bot)
      bot.respond(REGEXP_EPISODE) do |room, nick, msg, matches|
        query = matches[1]
        data = self.exec(query)
        if data[:error]
          bot.send(room, data[:url])
          bot.send(room, "Error: #{data[:error]}")
        else
          bot.send(room, data[:url])
          bot.send(room, data[:summary])
        end
      end

      # TODO スタッフリストを返すようにする
      bot.respond(REGEXP_STAFF) do |room, nick, msg, matches|
        query = matches[1]
        data = self.exec(query)
        bot.send(room, 'スタッフのリストを返すようにします')
        # if data[:error]
        #   bot.send(room, data[:url])
        #   bot.send(room, "Error: #{data[:error]}")
        # else
        #   bot.send(room, data[:url])
        #   bot.send(room, data[:summary])
        # end
      end

      # TODO キャストリストを返すようにする
      bot.respond(REGEXP_CAST) do |room, nick, msg, matches|
        query = matches[1]
        data = self.exec(query)
        bot.send(room, 'キャストのリストを返すようにします')
        # if data[:error]
        #   bot.send(room, data[:url])
        #   bot.send(room, "Error: #{data[:error]}")
        # else
        #   bot.send(room, data[:url])
        #   bot.send(room, data[:summary])
        # end
      end
    end

    def self.exec(query)
      # Wikipediaページ名でもURLでも動作するように
      if query.match('http://ja.wikipedia.org')
        link = query
      else
        link = URI.escape("http://ja.wikipedia.org/wiki/#{query}#.E5.90.84.E8.A9.B1.E3.83.AA.E3.82.B9.E3.83.88")
      end

      summary = ''
      doc = Nokogiri::HTML(open(link))
      doc.encoding = 'UTF-8'
      doc.css('.wikitable').each do |table|
        next if table.css('tr').size < 2
        # 1行目が「1stシーズン」など、2行目に話数、サブタイトルがある場合に対応
        text = ''
        text << table.css('tr')[0].text
        text << table.css('tr')[1].text
        next unless text.match('サブタイトル')

        # 話数、サブタイトルのindexを取得する
        nav_index = 0
        episode_index = 0
        subtitle_index = 1
        table.css('tr').each_with_index do |tr, i|
          break nav_index = i if tr.text.match('サブタイトル')
        end
        table.css('tr')[nav_index].css('th').each_with_index do |th, i|
          episode_index = i if th.text == '話数'
          subtitle_index = i if th.text == 'サブタイトル'
        end

        # エピソード毎の話数とサブタイトルを取得する
        table.css('tr').each do |tr|
          episodes = []
          episodes << tr.css('th').first.text if tr.css('th').size > 0
          next if tr.css('td').size == 0
          tr.css('td').each do |td|
            episodes << td.text.gsub(/\n/, '')
          end
          summary << "#{episodes[episode_index]} | #{episodes[subtitle_index]}\n"
        end
      end
      if summary.length > 0
        {url: link, summary: summary}
      else
        {url: link, error: '各話リストの話数が存在しません'}
      end
    rescue => e
      {url: link, error: e.inspect}
    end

  end
end

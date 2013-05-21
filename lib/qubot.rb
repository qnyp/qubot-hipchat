require 'active_support/all'
require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'

require_relative '../lib/jabber/muc/mucclient'

if RUBY_VERSION >= "1.9"
  # Encoding patch
  require 'socket'
  class TCPSocket
    def external_encoding
      Encoding::BINARY
    end
  end

  require 'rexml/source'
  class REXML::IOSource
    alias_method :encoding_assign, :encoding=
    def encoding=(value)
      encoding_assign(value) if value
    end
  end

  begin
    # OpenSSL is optional and can be missing
    require 'openssl'
    class OpenSSL::SSL::SSLSocket
      def external_encoding
        Encoding::BINARY
      end
    end
  rescue
  end
end

module Qubot
end

require_relative 'qubot/runner'
require_relative 'qubot/plugin/cv'
require_relative 'qubot/plugin/google_images'
require_relative 'qubot/plugin/niconico'
require_relative 'qubot/plugin/pixiv'
require_relative 'qubot/plugin/status'
require_relative 'qubot/plugin/wikipedia'

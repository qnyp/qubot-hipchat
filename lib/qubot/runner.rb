class Qubot::Runner

  attr_accessor :config, :client, :mucs, :logger, :room_table, :plugins, :hear_handlers, :respond_handlers

  def initialize(config, &block)
    if config[:jabber_debug]
      Jabber.logger = config[:logger]
      Jabber.debug = true
    end

    self.hear_handlers = {}
    self.respond_handlers = {}

    self.config = config
    self.client = Jabber::Client.new(config[:jid])
    self.logger = config[:logger] || Logger.new('/dev/null')

    instance_eval &block

    self.mucs = {}
    self.room_table = {}
    config[:rooms].each do |jid|
      name = room_id_to_name(jid)
      self.room_table[name] = jid
      self.mucs[name] = Jabber::MUC::SimpleMUCClient.new(client)
    end

    self.plugins.each do |plugin_class|
      # initialize plugins
      plugin_class.init(self) if plugin_class.respond_to?(:init)

      # register plugins
      plugin_class.register(self)
    end

    self
  end

  def use(plugin_class)
    self.plugins ||= []
    self.plugins << plugin_class
  end

  def hear(regexp, &block)
    logger.debug "Register hear handler: regexp = #{regexp}"
    self.hear_handlers[regexp] = block
  end

  def respond(regexp, &block)
    logger.debug "Register respond handler: regexp = #{regexp}"
    self.respond_handlers[regexp] = block
  end

  def connect
    logger.debug "connect"
    client.connect
    client.auth(config[:password])
    client.send(Jabber::Presence.new.set_type(:available))

    salutation = config[:nick]

    self.mucs.each do |room, muc|
      muc.on_message do |time, nick, text|
        self.hear_handlers.each do |regexp, handler|
          if text =~ regexp
            begin
              handler.call(room, nick, text, Regexp.last_match)
            rescue => e
              msg = "Exception: #{e.inspect}: #{e.backtrace.join("\n")}"
              logger.error msg
              send(room, msg)
            end
          end
        end

        logger.debug "text = #{text}"
        logger.debug /^@?#{salutation}\s+(.+)$/.to_s
        next unless text =~ /^@?#{salutation}\s+(.+)$/i

        command = Regexp.last_match[1]
        logger.debug "Command: #{command}"

        self.respond_handlers.each do |regexp, handler|
          if command =~ regexp
            logger.debug "Call respond handler"
            begin
              handler.call(room, nick, text, Regexp.last_match)
            rescue => e
              msg = "Exception: #{e.inspect}: #{e.backtrace.join("\n")}"
              logger.error msg
              send(room, msg)
            end
          end
        end
      end

      muc.join(self.room_table[room] + '/' + config[:name])
    end

    self
  end

  def send(room, msg)
    logger.debug "send: #{room}, #{msg}"
    muc = self.mucs[room]
    muc.send Jabber::Message.new(muc.room, msg)
  end

  def run
    self.logger.warn "running"
    loop { sleep 1 }
  end


  private

  def room_id_to_name(jid)
    jid =~ /^\d+_([^@]+)@.+$/ ? $1 : jid
  end

end

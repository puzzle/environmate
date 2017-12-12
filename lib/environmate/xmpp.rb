require 'xmpp4r'

module Environmate
  class Xmpp

    def self.init
      @xmpp_settings = Environmate.configuration['xmpp']
      if @xmpp_settings
        jid = Jabber::JID.new(@xmpp_settings['username'])
        @xmpp_client = Jabber::Client.new(jid)
        @xmpp_client.connect
        @xmpp_client.auth(@xmpp_settings['password'])
      end
    rescue => e
      @xmpp_client = nil
      Envionmate.log.error("Unable to initialize Xmpp client: #{e.message}")
    end

    def self.client
      @xmpp_client
    end

  end
end

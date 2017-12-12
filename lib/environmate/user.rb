#
# This class represents a user which triggered the hook.
#
require 'xmpp4r'

module Environmate
  class User

    def initialize(email = nil)
      @email         = email
      @xmpp_client   = Environmate::Xmpp.client
      @xmpp_settings = Environmate.configuration['xmpp']
      if @xmpp_settings && @xmpp_settings['users'].has_key?(@email)
        @xmpp_user   = @xmpp_settings['users'][@email]
        Envionmate.log.info("Xmpp user found #{@xmpp_user}")
      end
      @response      = []
    end

    # Send a message to the user
    #
    # * +severity+ - Message severity (log level)
    # * +message+  - The message
    def notify(severity, message)
      Envionmate.log.log(Logger.const_get(severity.to_s.upcase), message)
      @response << [severity, message]
      if @xmpp_client && @xmpp_user
        xmpp_message = Jabber::Message.new(@xmpp_user, format(severity, message))
        @xmpp_client.send(xmpp_message)
      end
    end

    def format(severity, message)
      "#{severity.to_s.upcase}: #{message}"
    end

    # Get array of messages for the response
    def response
      @response
    end

  end
end


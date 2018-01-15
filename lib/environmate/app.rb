#
# This is the main application class
#
require 'json'
require 'sinatra/base'
require 'environmate'

module Environmate
  class App < Sinatra::Base

    def self.run!(options = {})
      Environmate.load_configuration(settings.environment.to_s, options[:config_file])
      configuration = Environmate.configuration

      logfile  = options[:foreground] ? STDOUT : configuration['logfile']
      loglevel = options[:verbosity] || configuration['loglevel']
      Environmate.logger = Logger.new(logfile)
      Environmate.log.level = Logger.const_get(loglevel.upcase)

      Environmate::Xmpp.init

      server_settings = configuration['server_settings']

      if server_settings[:SSLEnable]
        require 'webrick/https'

        ssl_cert = server_settings[:SSLCertificate] || ""
        ssl_key  = server_settings[:SSLPrivateKey] || ""
        # replace cert filename with content
        if File.exists?(ssl_cert)
          server_settings[:SSLCertificate] = OpenSSL::X509::Certificate.new(File.open(ssl_cert).read)
        end
        if File.exists?(ssl_key)
          server_settings[:SSLPrivateKey] = OpenSSL::PKey::RSA.new(File.open(ssl_key).read)
        end
      end

      Rack::Handler::WEBrick.run(self, server_settings)
    end

    #
    # push hook for deployment of dynamic environments
    # from gitlab
    #
    post '/gitlab_push' do
      data         = JSON.parse(request.body.read)
      user         = Environmate::User.new(data['user_email'])
      branch       = data['ref'].gsub('refs/heads/', '')
      old_revision = data['before'].to_s
      new_revision = data['after'].to_s

      # gitlab uses a rev with only 0 to signal branch removal
      new_revision = nil if new_revision[/^0+$/]
      puppet_env = Environmate::EnvironmentManager.env_from_branch(branch)

      unless puppet_env.nil?
        deployment = Environmate::Deployment.new(user, puppet_env, new_revision, old_revision)
        deployment.deploy_dynamic
      end

      content_type :json
      user.response.to_json
    end

    #
    # Deploy hook for static environments
    #
    post '/deploy' do
      data       = JSON.parse(request.body.read)
      user       = Environmate::User.new
      puppet_env = data['environment']
      revision   = data['revision']
      token      = data['token']

      deployment = Environmate::Deployment.new(user, puppet_env, revision)
      deployment.deploy_static(token)

      content_type :json
      user.response.to_json
    end

  end
end

#
# Environmate CLI
#
require 'gli'
require 'environmate'
require 'environmate/cli/global_options'
require 'environmate/cli/command_server'

module Environmate
  module Cli
    include GLI::App
    extend self

    program_desc 'Puppet environment deployment tool'
    version Environmate::VERSION

    subcommand_option_handling :normal
    arguments :strict

    global_options(self)

    pre do |global,command,options,args|
      ENV['GLI_DEBUG'] = 'true' if global[:trace]

      configuration = Environmate.load_configuration(global[:config])

      logfile  = global[:foreground] ? STDOUT : configuration['logfile']
      loglevel = global[:verbosity] || configuration['loglevel']
      Environmate.logger = Logger.new(logfile)
      Environmate.log.level = Logger.const_get(loglevel.upcase)

      true
    end

    command_server(self)
  end
end

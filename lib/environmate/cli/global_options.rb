#
# Global Options for the CLI
#
module Environmate::Cli
  def self.global_options(base)
    base.class_eval do
      desc 'Specify environmate configuration file'
      arg_name 'CONFIG'
      flag [:c, :config]

      desc 'Log Verbosity: ERROR, WARN, INFO, DEBUG'
      default_value 'INFO'
      arg_name 'VERBOSITY'
      flag [:v, :verbosity]

      desc 'Print backtrace on error'
      default_value false
      arg_name 'DIR'
      switch [:t, :trace]

      desc 'Log to console instead of logfile and don\'t daemonize when run as server'
      default_value false
      switch [:f, :foreground]
    end
  end
end

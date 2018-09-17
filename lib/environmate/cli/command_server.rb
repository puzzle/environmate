#
# CLI component to run Environmate as a Server
#
module Environmate::Cli
  def self.command_server(base)
    base.class_eval do
      desc 'Run environmate as a webhook receiver'
      command :server do |c|

        c.desc 'Rack environment'
        c.default_value 'production'
        c.flag [:rack_env]

        c.action do |global_options,options,args|
          require 'environmate/app'
          Environmate::App.run!(options)
        end
      end
    end
  end
end

#
# Simple configuration loader from yaml
#
require 'yaml'

module Environmate

  def self.load_configuration(config_file = nil)
    config_file ||= config_location
    if config_file.nil?
      raise "No configuration file was provided"
    end
    unless File.exists?(config_file)
      raise "Configuration file #{config_file} does not exist"
    end
    config = YAML.load_file(config_file)
    @configuration = config_defaults.merge(config)
  end

  def self.configuration
    @configuration
  end

  private

  def self.config_defaults
    {
      'logfile'                     => '/var/log/enviromate.log',
      'loglevel'                    => 'WARN',
      'environment_path'            => '/etc/puppetlabs/code/environments',
      'lockfile_path'               => '/var/run/lock/environmate',
      'lockfile_options'            => {
        'timeout' => 300
      },
      'master_repository'           => 'http://gitlab.example.com/puppet/control',
      'master_branch'               => 'origin/master',
      'master_path'                 => '/etc/puppetlabs/code/environmate',
      'dynamic_environments_prefix' => 'env/',
      'static_environments'         => {},
      'install_modules_command'     => 'librarian-puppet install --destructive',
      'server_settings'             => {},
    }
  end

  def self.config_location
    [
      '/etc/environmate.yml',
      File.expand_path('~/.environmate.yml'),
    ].find{|c| File.exist?(c)}
  end

end

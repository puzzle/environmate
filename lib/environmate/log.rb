#
# Logger Helper
#
require 'logger'

module Environmate

  def self.log
    @log ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @log = logger
  end

end

require 'open3'

module Environmate
  module Command

    def command(cmd)
      stdout, stderr, status = Open3.capture3(cmd)
      unless status.success?
        message = []
        message << "Command '#{cmd}' failed"
        message << 'Status:' + status.exitstatus.to_s
        message << "Stdout:\n" + stdout.strip
        message << "Stderr:\n" + stderr.strip
        raise Environmate::DeployError, message.join("\n")
      end
      return stdout
    end

  end
end

require 'open4'

module Environmate
  module Command

    def command(cmd)
      pid, stdin, stdout, stderr = Open4.popen4(cmd)
      _, status = Process::waitpid2(pid)
      unless status.success?
        message = []
        message << "Command '#{cmd}' failed"
        message << 'Status:' + status.exitstatus.to_s
        message << "Stdout:\n" + stdout.read.strip
        message << "Stderr:\n" + stderr.read.strip
        raise Environmate::DeployError, message.join("\n")
      end
      return stdout
    end

  end
end

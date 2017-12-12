require 'open3'

module Environmate
  class GitRepository
    include Command

    def initialize(dir)
      @dir = dir
    end

    def submodule_update
      #git('submodule update --init') if submodules_outdated?
      git('submodule update --init')
    end

    def fetch
      git('fetch --prune')
    end

    def reset_hard(revision = 'HEAD')
      git("reset --hard #{revision}")
    end

    def clean
      git('clean -dff')
    end

    def checkout(revision)
      git("checkout #{revision}")
    end

    def remote_branches
      git('branch -r').each_line.map do |branch|
        branch[/^\s+origin\/(\S+).*$/, 1]
      end.compact
    end

    def clone(url)
      command("git clone #{url} #{@dir}")
    end

    def valid?
      status
      true
    rescue
      false
    end

    private

    def git(cmd)
      Dir.chdir(@dir) do
        command("git #{cmd}")
      end
    end

    def status
      git('status')
    end

    def submodules_outdated?
      !status.each_line.grep(/modified:.*\(new commits\)/).empty?
    end

  end
end

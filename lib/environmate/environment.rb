require 'open3'
require 'securerandom'

module Environmate
  class Environment
    include Command

    attr_reader :name

    def initialize(env_path)
      @env_path = env_path
      @name     = File.basename(env_path)
      @git      = GitRepository.new(env_path)
      @install_modules_command = Environmate.configuration['install_modules_command']
    end

    # This will update the current repository and
    # reset it to the specified revision.
    #
    # * +revision+ - The revision to update the repository to
    def update(revision)
      update_repo(revision)
      update_submodules if has_submodules?
      update_modules if has_puppetfile?
    end

    # This create a copy of the current repository
    # under the specified revision name and update
    # that environment to the specified revision.
    #
    # * +revision+ - The revision to update the repository to
    def copy(revision)
      new_path = new_env_path(revision)
      command("cp -r #{@env_path} #{new_path}")
      new_env = Environment.new(new_path)
      new_env.update(revision)
      new_env
    end

    # This will create a environment link to the repository
    #
    # * +puppet_env+ - The name of the link/environment
    def link(puppet_env)
      unless links.include?(puppet_env)
        temp_link_path = new_env_path(SecureRandom.hex)
        real_link_path = new_env_path(puppet_env)
        # relinking is not atomic in linux, but mv is
        # so we create a temporary link and rename it
        File.symlink(@env_path, temp_link_path)
        File.rename(temp_link_path, real_link_path)
      end
    end

    # get a list of all the links to this environment
    def links
      found_links = EnvironmentManager.links.find_all do |link,target|
        target == @name
      end
      found_links.map{|link, target| link}
    end

    def delete
      FileUtils.remove_entry_secure(@env_path)
    end

    def valid?
      @git.valid?
    end

    private

    def update_repo(revision)
      @git.fetch
      @git.reset_hard
      @git.clean
      @git.checkout(revision)
    end

    def update_submodules
      @git.submodule_update
    end

    def update_modules
      Dir.chdir(@env_path) do
        command(@install_modules_command)
      end
    end

    def has_submodules?
      gitmodules = File.join(@env_path, '.gitmodules')
      File.exist?(gitmodules)
    end

    def has_puppetfile?
      puppetfile = File.join(@env_path, 'Puppetfile')
      File.exist?(puppetfile)
    end

    def new_env_path(revision)
      base_dir = Environmate.configuration['environment_path']
      File.join(base_dir, revision)
    end

  end
end

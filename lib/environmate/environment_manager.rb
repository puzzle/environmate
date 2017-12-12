module Environmate
  class EnvironmentManager
    include Command

    def self.find(env_name)
      environments.find do |env|
        env.name == env_name ||
        env.links.any?{|link| File.basename(link) == env_name}
      end
    end

    def self.environments
      env_dir_entries('directory').map do |dir|
        env = Environment.new(dir)
        env.valid? ? env : nil
      end.compact
    end

    def self.links
      Hash[env_dir_entries('link').map do |dir|
        target = File.readlink(dir)
        [File.basename(dir), File.basename(target)]
      end]
    end

    # get the master environment and make sure it is created
    # and updated.
    def self.master
      master_path       = Environmate.configuration['master_path']
      master_repository = Environmate.configuration['master_repository']
      master_branch     = Environmate.configuration['master_branch']
      unless File.exists?(File.join(master_path,'.git'))
        git = GitRepository.new(master_path)
        git.clone(master_repository)
      end
      master_env = Environment.new(master_path)
      master_env.update("origin/#{master_branch}")
      master_env
    end

    # cleanup old links and environments
    def self.cleanup
      cleanup_links
      cleanup_environments
    end

    # puppet environment name from branch name
    def self.env_from_branch(branch)
      prefix = Environmate.configuration['dynamic_environments_prefix']
      if branch.start_with?(prefix)
        branch.gsub(prefix, '').gsub(/(\/|\-)/,'_')
      else
        nil
      end
    end

    private

    # returns an array of environments which has remote branches
    def self.envs_with_branches
      env_path = Environmate.configuration['master_path']
      git = GitRepository.new(env_path)
      git.remote_branches.map do |branch|
        env_from_branch(branch)
      end.compact
    end

    # returns an array of direcories in the environement path
    def self.env_dir_entries(ftype)
      env_path = Environmate.configuration['environment_path']
      Dir[env_path + '/*'].map do |dir|
        File.ftype(dir) == ftype ? dir : nil
      end.compact
    end

    # cleanup all the old links
    def self.cleanup_links
      env_path    = Environmate.configuration['environment_path']
      static_envs = Environmate.configuration['static_environments'].keys
      valid_links = envs_with_branches + static_envs
      old_links = links.keys - valid_links
      old_links.each do |old_link|
        old_link_path = File.join(env_path, old_link)
        File.delete(old_link_path)
      end
    end

    # cleanup all the old environments
    def self.cleanup_environments
      used_envs = links.values.uniq
      environments.each do |env|
        env.delete unless used_envs.include?(env.name)
      end
    end

  end
end

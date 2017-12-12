# This class controlls the deployment of puppet environments
require 'lockfile'

module Environmate
  class Deployment

    # create a new instance of Deployment
    #
    # * +user+         - The user who triggered the deployment
    # * +puppet_env+   - The puppet environment to deploy
    # * +revision+     - The revision which should be deployed in the environment
    # * +old_revision+ - The revision the environment had previously
    def initialize(user, puppet_env, revision, old_revision = nil)
      @user         = user
      @puppet_env   = puppet_env
      @revision     = revision
      @old_revision = old_revision
    end

    # Deploy a static environment
    #
    # * +token+      - The access token to deploy the environment
    def deploy_static(token)
      unless is_static_env?
        @user.notify(:error, "'#{@puppet_env}' is not a static environment! Deployment aborted!")
        return
      end
      return unless token_valid?(token)

      @user.notify(:info, "Push of static environment '#{@puppet_env}' received, attempting to deploy...")
      deploy
    end

    # Deploy a dynamic environment
    def deploy_dynamic
      if is_static_env?
        @user.notify(:error, "'#{@puppet_env}' is a static environment. There should not be a branch of the same name")
        return
      end

      @user.notify(:info, "Push of dynamic environment '#{@puppet_env}' received, attempting to deploy...")
      deploy
    end

    # Checks if the puppet environment is a static environment
    def is_static_env?
      Environmate.configuration['static_environments'].keys.include?(@puppet_env)
    end

    # Checks if the token ist valid
    #
    # * +token+ - The token received from the hook
    def token_valid?(token)
      real_token = Environmate.configuration['static_environments'][@puppet_env]['token']
      if real_token.nil?
        @user.notify(:error, "No token set for '#{@puppet_env}'")
        false
      elsif real_token == token
        true
      else
        @user.notify(:error, "Incorrect token for deployment of '#{@puppet_env}'")
        false
      end
    rescue
      @user.notify(:error, "Error while parsing configuration for '#{@puppet_env}'")
      false
    end

    # Deploy the puppet environment
    def deploy
      lockfile_path    = Environmate.configuration['lockfile_path']
      lockfile_options = Environmate.configuration['lockfile_options']
      Lockfile.new(lockfile_path, lockfile_options) do
        begin
          if @revision.nil? || @revision.empty?
            @user.notify(:info, 'Revision was empty. Only doing a cleanup...')
            EnvironmentManager.master
          else
            @user.notify(:info, "Starting deployment of '#{@puppet_env}'...")
            new_env = new_environment
            @user.notify(:info, "Linking '#{@puppet_env}' => '#{@revision}'")
            new_env.link(@puppet_env)
            @user.notify(:info, "Done! Starting cleanup...")
          end

          EnvironmentManager.cleanup
          @user.notify(:info, "Cleanup done!")
        rescue Environmate::DeployError => e
          @user.notify(:error, "Error during deployment: #{e.message}")
        rescue => e
          @user.notify(:error, 'Error during deployment. This is probably a bug')
          @user.notify(:error, e.class)
          @user.notify(:error, e.message)
          @user.notify(:error, e.backtrace)
        end
      end
    end

    private

    # check if the revision is already deployed, if not deploy it
    def new_environment
      new_env = EnvironmentManager.find(@revision)
      if new_env.nil?
        @user.notify(:info, "Revision '#{@revision}' not already deployed, trying to find optimal starting point for deployment")
        env = EnvironmentManager.find(@old_revision) ||
              EnvironmentManager.find(@puppet_env) ||
              EnvironmentManager.master
        @user.notify(:info, "Deploying '#{@revision}' from copy of '#{env.name}'")
        new_env = env.copy(@revision)
        @user.notify(:info, "Deployment of '#{@revision}' done!")
      else
        @user.notify(:info, "Revision '#{@revision}' is already deployed")
      end
      new_env
    end

  end
end


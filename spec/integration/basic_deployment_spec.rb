require 'spec_helper'
require 'fileutils'
require 'erb'

RSpec.describe 'app' do
  # create the test git repositories
  before :all do
    @project_root = Dir.pwd
    unless File.exist?('/tmp/puppet/submodule')
      FileUtils.mkdir_p('/tmp/puppet/submodule')
      Dir.chdir('/tmp/puppet/submodule') do
        %x[echo "I am a Submodule" >> README]
        %x[git init && git add . && git commit -m "initial commit" &> /dev/null]
      end
    end
    unless File.exists?('/tmp/example-testmodule')
      FileUtils.cp_r('spec/fixtures/example-testmodule', '/tmp/puppet/')
    end
    unless File.exist?('/tmp/puppet/upstream')
      FileUtils.mkdir_p('/tmp/puppet/upstream')
      FileUtils.cp('spec/fixtures/Puppetfile',      '/tmp/puppet/upstream/')
      FileUtils.cp('spec/fixtures/Puppetfile.lock', '/tmp/puppet/upstream/')
      Dir.chdir('/tmp/puppet/upstream') do
        %x[echo "I am a Puppet control repo" >> README]
        %x[echo "modules/" >> .gitignore]
        %x[git init && git add . && git commit -m "initial commit" &> /dev/null]
        %x[git submodule add file:///tmp/puppet/submodule/ &> /dev/null]
        %x[git commit -m "add submodule" &> /dev/null]
        %x[git branch env/awesome_feature]
      end
    end
  end

  let(:headers){{
    :accept       => 'application/json',
    :content_type => 'application/json'
  }}
  let(:branch_rev) do
    %x[git -C /tmp/puppet/upstream rev-parse env/awesome_feature].chomp
  end
  let(:old_branch_rev) do
    %x[git -C /tmp/puppet/upstream rev-parse HEAD^].chomp
  end
  let(:create_request) do
    {
      'user_email' => 'tux@example.com',
      'ref'        => 'refs/heads/env/awesome_feature',
      'before'     => '0000000000000000000000000000000000000',
      'after'      => branch_rev,
    }.to_json
  end
  let(:update_request) do
    {
      'user_email' => 'tux@example.com',
      'ref'        => 'refs/heads/env/awesome_feature',
      'before'     => old_branch_rev,
      'after'      => branch_rev,
    }.to_json
  end
  let(:delete_request) do
    {
      'user_email' => 'tux@example.com',
      'ref'        => 'refs/heads/env/some_other_feature',
      'before'     => 'abc123',
      'after'      => '0000000000000000000000000000000000000',
    }.to_json
  end
  let(:example_path) {'/tmp/puppet/environments/awesome_feature'}

  before :each do
    Dir.chdir(@project_root)
    FileUtils.rm_rf('/tmp/puppet/environments')
    FileUtils.mkdir_p('/tmp/puppet/environments')
  end

  describe '/gitlab_push' do
    it 'should create the env branch if a new one was pushed' do
      post '/gitlab_push', create_request, headers
      expect(File.exist?(example_path)).to be true
      expect(File.exist?(example_path + '/submodule')).to be true
      expect(File.exist?(example_path + '/modules/testmodule')).to be true
    end

    it 'should update the env branch' do
      # make sure the env branch is already there with an old version
      %x[git clone -q file:///tmp/puppet/upstream /tmp/puppet/environments/#{old_branch_rev}]
      %x[git -C /tmp/puppet/environments/#{old_branch_rev} reset --hard HEAD^]
      %x[ln -s /tmp/puppet/environments/#{old_branch_rev} #{example_path}]
      expect(File.exist?(example_path)).to be true
      expect(File.exist?("/tmp/puppet/environments/#{old_branch_rev}")).to be true
      expect(File.exist?("/tmp/puppet/environments/#{branch_rev}")).to be false
      expect(%x[git -C #{example_path} rev-parse HEAD].chomp).to eq(old_branch_rev)

      post '/gitlab_push', update_request, headers
      expect(File.exist?(example_path)).to be true
      expect(File.exist?("/tmp/puppet/environments/#{old_branch_rev}")).to be false
      expect(File.exist?("/tmp/puppet/environments/#{branch_rev}")).to be true
      expect(%x[git -C #{example_path} rev-parse HEAD].chomp).to eq(branch_rev)
      expect(File.exist?(example_path + '/submodule')).to be true
      expect(File.exist?(example_path + '/modules/testmodule')).to be true
    end

    it 'should delete old branches and links' do
      # make sure the env branch is already there with an old version
      old_env    = '/tmp/puppet/environments/abc123'
      old_dir    = '/tmp/puppet/environments/somedir'
      old_link   = '/tmp/puppet/environments/fooo'
      valid_env  = '/tmp/puppet/environments/123abc'
      valid_link = example_path
      Dir.mkdir(old_dir)
      FileUtils.cp_r('/tmp/puppet/upstream', old_env)
      FileUtils.cp_r('/tmp/puppet/upstream', valid_env)
      File.symlink(old_env, old_link)
      File.symlink(valid_env, valid_link)

      post '/gitlab_push', delete_request, headers
      expect(File.exist?(old_env)).to be false
      expect(File.exist?(old_link)).to be false
      expect(File.exist?(valid_env)).to be true
      expect(File.exist?(valid_link)).to be true
    end

    it 'should delete old branches and links' do
      threads = []
      2.times do
        threads << Thread.new do
          post '/gitlab_push', update_request, headers
        end
      end
      threads.each {|t| t.join}
    end

  end

  let(:deploy) do
    {
      :environment => 'nonprod',
      :revision    => branch_rev,
      :token       => 'abc123'
    }.to_json
  end
  let(:deploy_invalid_token) do
    {
      :environment => 'nonprod',
      :revision    => branch_rev,
      :token       => 'invalid'
    }.to_json
  end
  let(:nonprod){'/tmp/puppet/environments/nonprod'}

  describe '/delpoy' do
    it 'should deploy the static nonprod environment' do
      post '/deploy', deploy, headers
      expect(File.exist?(nonprod)).to be true
      expect(File.exist?(nonprod + '/submodule')).to be true
      expect(File.exist?(nonprod + '/modules/testmodule')).to be true
    end

    it 'should trow an error if the token is wrong' do
      post '/deploy', deploy_invalid_token, headers
      expect(File.exist?(nonprod)).to be false
    end
  end

end

# Environmate

Environmate is a ruby sinatra web application to deploy
Puppet code to a Puppet master.

This web application will completely take control of your
environments directory and purge every other environment already in there
or which is deployed by other means.

Currently it supports webhook events from Gitlab, but this may be easily
extended in the future to more GIT web frontends.

## Installation

Environmate comes as ruby gem. You can install it on
your puppet master by running:

    $ /opt/puppetlabs/puppet/bin/gem install environmate

## Usage

Environmanet comes with puma included and no additional setup
is required. Simply run environmate from the console:

    $ /opt/puppetlabs/puppet/bin/environmate --help

## Environment Management

Environmate provides two different ways to deploy code which wich represent two
different use-cases and are explained in the following section.

### Dynamic Environments

Dynamic environments are puppet environments which are derived from a
GIT branch which starts with a defined prefix. The default prefix is
'env/'. All other branches will simply be ignored.

To deploy such branches as environments a web hook has to registered in Gitlab
with the API endpoint '/gitlab_push' on push events. The web application will
examine each push event and deploy the specified revision.

The typical use-case for this type of deployments is for development purposes:

On the local development machine start a new branch and push it to your GIT
server:

    $ git checkout -b env/mynewfeature
    $ vim modules/foo/manifests/init.pp
    $ git commit -a -m "my awesome new feature"
    $ git push -u origin env/mynewfeature

Enviornmate will now atomatically create a new environment with the name
'mynewfeature' which you can test on any node with:

    $ puppet agent --test --environment mynewfeature

If you delete the branch the environment will be removed again.

### Static Environments

Static environments are predefined environments which can be deployed with
a different API endpoint '/deploy'. The main purpose is to deploy arbitrary
revisions from a deployment pipeline outside the version control system.
The push request to this endpoint has to contain the following data:

    {
      "environment": "name_of_the_puppet_environment",
      "token":       "secret_token",
      "revision":    "git_commit_revision_(sha1)"
    }

Those environments and their tokens have to be pre-configured in order to work.
Dynamic environments can not have the same name as a static environment and will
fail to deploy if created.

## Features

### Atomic Deployments

Environmate deploys the code for the revisions in directories with the name
of the SHA1 reference. Only after the environment is completely deployed it will add
a link with the puppet environment name or switch an existing name in an atomic operation
which guarantees that there is never an invalid environment.

If the deployment of a revision for some reason fails, the link will remain on the old
revision and the puppet master stays unaffected.

### Notifications

Since the Gitlab hook provides information about the users email it is possible to
configure a mapping of email to jabber accounts to inform the user in a timely
fashion about the progress of the deployment.

However this will only work for ruby > 1.9.3 since xmpp4r uses classes not
available in previous ruby versions.

## Configuration

Environmate will attempt to load the configuration in the following order.
It will use the first yaml file it finds:

- '/etc/environmate.yml'
- '~/.environmate.yml'

Additionally you can provide a configuration file when starting the environmate
service:

    $ /opt/puppetlabs/puppet/bin/environmate --config /path/to/my/conf.yml

Here is a complete example config:

    production:
      environment_path: '/etc/puppetlabs/code/environments'

      lockfile_path: '/var/run/lock/puppet_deploy_lock'
      lockfile_options:
        timeout: 300

      logfile: '/var/log/environmate.log'
      loglevel: 'INFO'

      master_repository: 'http://gitlab.exmple.com/puppet/control'
      master_branch: 'origin/master'
      master_path: '/etc/puppetlabs/code/environmate_master'

      dynamic_environments_prefix: 'env/'

      static_environments:
        nonprod:
          token: 'abc123'
        prod:
          token: '123abc'

      xmpp:
        username: 'foo@jabber.example.com'
        password: 'foofoofoo'
        users:
          - bob@example.com: 'bob@jabber.example.com'
          - alice@example.com: 'alice@jabber.example.com'

## Internals

### Locking

To prevent deployment processes from interfering with each other, only one deployment
can happen at a certain time. Environmate will halt additional deployment requests
until the deployment in progress is finished in which case the next deployment waiting will
be started automatically.

### Master Repository

The master repository is only there to work as a starting point for new branches, so we
don't have to clone the whole environment from scratch each time. Environmate
will try to find the shortest way to deploy an environment from the already deployed
revisions. If no good starting point can be evaluated it will default to the master.

## Debugging

To easily debug environmate you can start it manually with the foreground flag to get all
the log output to the console. This way you don't have to adjust the config:

    $ /opt/puppetlabs/puppet/bin/environmate --foreground --verbosity DEBUG

If you want to see stacktraces add the trace flag:

    $ /opt/puppetlabs/puppet/bin/environmate --foreground --verbosity DEBUG --trace

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/puzzle/environmate.
This project is intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the GNU General Public License 3.0
(https://www.gnu.org/licenses/gpl-3.0.en.html)

## Code of Conduct

Everyone interacting in the Environmate project’s codebases, issue trackers, chat rooms
and mailing lists is expected to follow the
[code of conduct](https://github.com/puzzle/environmate/blob/master/CODE_OF_CONDUCT.md).

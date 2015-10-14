# vagrant-listen-server

Forward filesystem events from a host to a client

Vagrant's shared folders don't pass file modification notifications to the
guest. That means editing files locally won't trigger off inotify file events,
which means any build / test / servers that need to reload on change have to
poll for changes.

If you're using virtualbox, vboxsf performance really really sucks. Hard links
are impossible. Statting takes forever.
 * http://mitchellh.com/comparing-filesystem-performance-in-virtual-machines

Since polling implementations will probably rely on statting the file in some
way, this creates a pretty awful experience.

I have tried to keep dependencies to a minimum and only rely on ruby stdlib and
gems already required by vagrant. The listen gem is used by vagrant (as part
of rsync-auto) so it is used for file system notifications.


## Clients

Clients should run inside the virtual machine as part of your build process.
Instead of listenting for filesystem events, they should listen on a tcp
connection.

The message format is a newline separated, json encoded object with keys `type`
and `data`. The two message types:

**listen**

    {"type": "listen", "data": [modified, added, removed]}

data is an array of 3 arrays containing the full path of the files that are
    modified, added and removed (in that order).

**ping**

    {"type": "ping", "data": "message to be echoed"}

response will be of type "pong". Data will be echoed back to the client.


In many cases, a simple client that touches all modified files on the guest is
sufficient, however you'll have to be aware of loops created if filesystem
notifications are passed back from the guest to the host in any way. Listen
coalesces events for us, so there is no need to do so in your client.

See the [examples](/examples) section for some implementations. Currently there
is solely my node based client, but if you're using this in any other
languages, please add your client and submit a pull request!


## Keepalives

Ideally, the client and server sockets would both support keepalives. But we
can't rely on that working on both guest and host - windows has spotty support,
and many languages don't give control over socket flags (it's awkward in ruby).
Instead, the client can send a ping message to check the connection is alive.

A simple client can safely ignore keepalive messages.

http://www.tldp.org/HOWTO/html_single/TCP-Keepalive-HOWTO/


## Usage

Install the plugin:

`vagrant plugin install vagrant-listen-server`

Then in your Vagrantfile:

```ruby
config.vm.synced_folder '/host/code', '/client/code'

# You have to specify a private network for the guest to connect to.
config.vm.network :private_network, ip: '172.16.172.16'

if Vagrant.has_plugin? 'vagrant-listen-server'
  # The host will always be the same IP as the private network with the last
  # octet as .1
  config.listen_server.ip = '172.168.172.1'
  config.listen_server.port = 4000
  config.listen_server.folders = '/host/code'
  config.listen_server.pid_file = '/tmp/servername.listen.pid'
end
```

Because sleep states of both the host and guest machines can mess with long
connections in unexpected ways, you can use the command to control the listen
server.

```bash
vagrant listen stop
vagrant listen start
vagrant listen status
```


## Other options

 * [rsync-auto](http://docs.vagrantup.com/v2/cli/rsync-auto.html)

Filesystem is shared using rsync-auto protocol instead of vboxsf

 * [vagrant-mirror](https://github.com/ingenerator/vagrant-mirror/)

Hasn't been updated to work with vagrant's new plugin system.


## Development

To develop locally
```
gem build vagrant-listen-server.gemspec
vagrant plugin install vagrant-listen-server-*.gem
```

Other good vagrant plugins used for reference:
 * https://github.com/mitchellh/vagrant-aws/blob/master/Rakefile
 * vagrant-ls - http://www.noppanit.com/create-simple-vagrant-plugin/
 * vargant-notify - https://github.com/fgrehm/vagrant-notify/blob/master/lib/vagrant-notify/action/start_server.rb


## TODO:

Listen maybe is a bit of a resource hog:
 * https://github.com/mitchellh/vagrant/issues/3249

There might be some better, native implementations that make this faster. e.g.
 * https://fsnotify.org/

Gemspecs don't allow platform specific requirements, so we have to include all
the gems for filesystem events. It looks like the only great solution to this
is to switch to a separate gem for each platform...
 * http://stackoverflow.com/questions/8940271/build-a-ruby-gem-and-conditionally-specify-dependencies

You can automate the install pretty easily though:
 * http://stackoverflow.com/questions/4596606/rubygems-how-do-i-add-platform-specific-dependency/10249133#10249133
 * http://en.wikibooks.org/wiki/Ruby_Programming/RubyGems#How_to_install_different_versions_of_gems_depending_on_which_version_of_ruby_the_installee_is_using

Fork in a way that will work with windows. Childprocess gem is included with
vagrant by default - see if it will fit the bill.
 * https://github.com/jarib/childprocess

There's also a "subprocess" module under vagrant util
 * https://github.com/mitchellh/vagrant/blob/master/lib/vagrant/util/subprocess.rb

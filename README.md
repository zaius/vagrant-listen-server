# vagrant-listen-server

Forward filesystem events from a host to a client

To develop locally
```
bundle cache
gem build vagrant-listen-server.gemspec
mv vagrant-listen-server-0.0.1.gem vendor/cache
cd vendor/cache
gem generate_index
vagrant plugin install vagrant-listen-server --plugin-source file://`pwd`

# This seems to work just fine...
vagrant plugin install vagrant-listen-server-0.0.1.gem
```

Other good vagrant plugins used for reference:
* https://github.com/mitchellh/vagrant-aws/blob/master/Rakefile
* vagrant-ls - http://www.noppanit.com/create-simple-vagrant-plugin/


## Usage

`vagrant plugin install vagrant-listen-server`

require 'vagrant-listen-server/version'
require 'vagrant-listen-server/plugin'
require 'vagrant-listen-server/command'

module VagrantPlugins
  module ListenServer
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end

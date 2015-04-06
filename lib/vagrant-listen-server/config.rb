module VagrantPlugins
  module ListenServer
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :ip
      attr_accessor :port
      attr_accessor :folders
    end
  end
end

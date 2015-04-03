module Vagrant
  module ListenServer
    class Plugin < Vagrant.plugin('2')
      name 'ListenServer'

      description <<-DESC
        Start a Listen server to forward filesystem events to the client VM.
      DESC

      command 'ls' do
        require_relative 'command'
        Command
      end
    end
  end
end

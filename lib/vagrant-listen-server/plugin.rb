require_relative 'action'
require_relative 'daemon'

require 'rbconfig'
os = RbConfig::CONFIG['target_os']

require 'rb-fsevent' if os =~ /darwin/i
require 'rb-kqueue' if os =~ /bsd|dragonfly/i
require 'rb-inotify' if os =~ /linux/i
require 'wdm' if Gem.win_platform?


module VagrantPlugins
  module ListenServer
    class Plugin < Vagrant.plugin('2')
      name 'ListenServer'

      description <<-DESC
        Start a Listen server to forward filesystem events to the client VM.
      DESC

      config(:listen_server) do
        require_relative 'config'
        Config
      end

      command :listen do
        require_relative 'command'
        Command
      end

      action_hook(:listen_server, :machine_action_up) do |hook|
        hook.append(Action::StartServer)
      end

      action_hook(:listen_server, :machine_action_halt) do |hook|
        hook.append(Action::KillServer)
      end

      action_hook(:listen_server, :machine_action_suspend) do |hook|
        hook.append(Action::KillServer)
      end

      action_hook(:listen_server, :machine_action_destroy) do |hook|
        hook.append(Action::KillServer)
      end

      action_hook(:listen_server, :machine_action_reload) do |hook|
        hook.append(Action::StartServer)
      end

      action_hook(:listen_server, :machine_action_resume) do |hook|
        hook.append(Action::StartServer)
      end
    end
  end
end

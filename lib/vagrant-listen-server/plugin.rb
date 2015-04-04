require_relative 'action'

module VagrantPlugins
  module ListenServer
    class Plugin < Vagrant.plugin('2')
      name 'ListenServer'

      description <<-DESC
        Start a Listen server to forward filesystem events to the client VM.
      DESC

      config(:listenserver) do
        require_relative 'config'
        Config
      end

      action_hook(:listenserver, :machine_action_up) do |hook|
        hook.append(Action::StartServer)
      end

      action_hook(:listenserver, :machine_action_halt) do |hook|
        hook.append(Action::KillServer)
      end

      action_hook(:listenserver, :machine_action_suspend) do |hook|
        hook.append(Action::KillServer)
      end

      action_hook(:listenserver, :machine_action_destroy) do |hook|
        hook.append(Action::KillServer)
      end

      action_hook(:listenserver, :machine_action_reload) do |hook|
        hook.append(Action::StartServer)
      end

      action_hook(:listenserver, :machine_action_resume) do |hook|
        hook.append(Action::StartServer)
      end
    end
  end
end

module VagrantPlugins
  module ListenServer
    class Command < Vagrant.plugin('2', :command)
      def self.synopsis
        "Check the status of the vagrant-listen server"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant listen [start|stop|status]'
        end

        command = @argv.shift
        argv = parse_options opts

        with_target_vms nil, single_target: true do |vm|
          # puts "ENV #{vm.env.inspect}"
          # puts "CONFIG #{vm.config.inspect}"
          # puts "LISTEN #{vm.config.listen_server.inspect}"

          case command
          when 'status' then Daemon.status vm.config.listen_server
          when 'stop' then Daemon.stop vm
          when 'start' then Daemon.start vm
          else
            puts 'Unknown command'
            exit 1
          end
        end

        0
      end
    end
  end
end

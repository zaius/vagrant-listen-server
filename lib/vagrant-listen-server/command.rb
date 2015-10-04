module VagrantPlugins
  module ListenServer
    class Command < Vagrant.plugin('2', :command)
      def self.synopsis
        "Check the status of the vagrant-listen server"
      end

      def initialize(argv, env)
        @argv = argv
        @env  = env
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant listen [start|stop|status]'
        end
        argv = parse_options(opts)

        exit 1 if not argv.count == 1
        command = argv[0]

        case command
        when 'status' then status
        when 'stop' then stop
        when 'start' then start
        else
          @ui.info 'Unknown command'
          exit 1
        end

        0
      end

      def start
        @logger.info 'Do something here'
      end

      def stop
        @logger.info 'Stopping server'
        @env[:interrupted] = true
      end

      def status
        config = @env[:machine].config.listen_server
        if File.exists? config.pid_file
          pid = File.read config.pid_file
          begin
            Process.kill 0, pid.to_i
            @ui.info "Server running - PID #{pid}"
          rescue Errno::ESRCH
            @ui.info 'Stale PID file - no server found'
            File.delete config.pid_file
          end
        else
          @ui.info 'No listen server found'
        end
      end
    end
  end
end

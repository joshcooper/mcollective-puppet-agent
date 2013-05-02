module MCollective
  module Util
    module PuppetAgentMgr::V3
      module Windows
        extend Windows
        require 'win32/service'

        # is the agent daemon currently running?
        def daemon_present?
          # REMIND: make service name configurable
          case Win32::Service.status('pe-puppet').current_state
          when "running", "continue pending", "start pending"
            true
          else
            false
          end
        rescue Win32::Service::Error
          false
        end

        # is the agent currently applying a catalog
        def applying?
          return false if disabled?

          begin
            pid = File.read(Puppet[:agent_catalog_run_lockfile])
            return has_process_for_pid?(pid)
          rescue Errno::ENOENT
            return false
          end
        rescue => e
          Log.warn("Could not determine if Puppet is applying a catalog: %s: %s: %s" % [e.backtrace.first, e.class, e.to_s])
          return false
        end

        def signal_running_daemon
          run_in_foreground([])
        end

        def has_process_for_pid?(pid)
          return false if pid.nil? or pid.empty?

          !!Process.kill(0, Integer(pid))
        rescue Errno::EPERM
          true
        rescue Errno::ESRCH
          false
        end
      end
    end
  end
end

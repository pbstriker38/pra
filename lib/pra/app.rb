require 'thread'

require 'pra/window_system_factory'
require 'pra/pull_request_service'
require 'pra/repository_wizard'
require 'pra/error_log'

Thread.abort_on_exception=true

module Pra
  class App
    def run
      if ARGV[0] == '-g'
        ARGV.clear #clear arguments for gets to work properly
        Pra::RepositoryWizard.start
      end
      @window_system = Pra::WindowSystemFactory.build('curses')
      @window_system.setup

      spawn_pull_request_fetcher

      @window_system.run_loop
    end

    def spawn_pull_request_fetcher
      Thread.new { pull_request_fetcher_thread }
    end

    def fetch_and_refresh_pull_requests
      @window_system.fetching_pull_requests
      new_pull_requests = []

      Pra::PullRequestService.fetch_pull_requests do |fetch|
        fetch.on_success do |pull_requests|
          new_pull_requests += pull_requests
        end

        fetch.on_error do |error|
          Pra::ErrorLog.log(error)
          @window_system.fetch_failed
        end
      end

      @window_system.refresh_pull_requests(new_pull_requests)
      
      Kernel.sleep(5 * 60)
    end

    def pull_request_fetcher_thread
      while( true ) do
        fetch_and_refresh_pull_requests
      end
    end
  end
end

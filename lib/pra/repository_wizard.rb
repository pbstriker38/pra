require 'json'
require 'rest_client'
require 'io/console'

module Pra
  class RepositoryWizard
    $built_json = "{:pull_sources=>["
    
    def self.start
      system('clear')
      print "Do you have a github account? (y or n) "
      STDOUT.flush
      if gets.chomp == 'y'
        $built_json += '{:type=>"github",:config=>{:protocol=>"https",:host=>"api.github.com",'
        self.get_github_credentials
        $built_json += ','
      end
      print "Do you have a stash account? (y or n) "
      STDOUT.flush
      if gets.chomp == 'y'
        $built_json += '{:type=>"stash",:config=>{:protocol=>"https",:host=>"stash.lax.reachlocal.com",'
        self.get_stash_credentials
      end
      $built_json += "]}"
      puts $built_json
      json = eval($built_json)
     
      file = File.open(File.expand_path('~/.pra.json'), 'w')
      file.write(JSON.pretty_generate(json))
      file.close
      
      system('clear')
    end

    def self.get_github_credentials
      system('clear')
      print "Please enter your github username: "
      STDOUT.flush
      username = gets.chomp
      print "Please enter your github password: "
      STDOUT.flush
      password = STDIN.noecho(&:gets)
      password = password.chomp

      $built_json += ":username=>\"#{username}\",:password=>\"#{password}\",:repositories=>["
      system('clear')

      self.retrieve_github_repos(username, password)
    end

    def self.retrieve_github_repos(username, password)
      resource_url = "https://api.github.com/user/repos"

      resource = RestClient::Resource.new resource_url, user: username, password: password
      
      parsed =  JSON.parse(resource.get, {:symbolize_names => true})
  
      parsed.each do |repo|
        print "Would you like to add #{repo[:name]} to pra? (y or n) "
        STDOUT.flush
        if gets.chomp == 'y'
          $built_json += "{:owner=>\"#{username}\",:repository=>\"#{repo[:name]}\"},"
        end
        puts "\n"
      end
      $built_json = $built_json.chomp(',')
      $built_json += "]}}"
      system('clear')
    end

    def self.get_stash_credentials
      system('clear')
      print "Please enter your stash username: "
      STDOUT.flush
      username = gets.chomp
      print "Please enter your stash password: "
      STDOUT.flush
      password = STDIN.noecho(&:gets)
      password = password.chomp
      
      $built_json += ":username=>\"#{username}\",:password=>\"#{password}\",:repositories=>["
      system('clear')

      self.retrieve_stash_repos(username, password)
    end

    def self.retrieve_stash_repos(username, password)
      resource_url = "https://stash.lax.reachlocal.com/rest/api/1.0/projects"

      resource = RestClient::Resource.new resource_url, user: username, password: password
      
      parsed =  JSON.parse(resource.get, {:symbolize_names => true})

      parsed[:values].each do |project|
        print "Would you like to add any repos from the #{project[:name]} project? (y or n) "
        STDOUT.flush

        if gets.chomp == 'y'
          project_url = resource_url + "/#{project[:key]}/repos"
  
          project_resource = RestClient::Resource.new project_url, user: username, password: password
        
          project_repos = JSON.parse(project_resource.get, {:symbolize_names => true})
        
          project_repos[:values].each do |repo|
            puts parsed[:values]
            puts project[:key]
            print "Would you like to add #{repo[:name]} to pra? (y or n) "
            STDOUT.flush
            if gets.chomp == 'y'
              $built_json += "{:project_slug=>\"#{project[:key]}\",:repository_slug=>\"#{repo[:name]}\"},"
            end
            puts "\n"
          end
        end
        system('clear')
      end
        $built_json = $built_json.chomp(',')
        $built_json += "]}}"
        system('clear')
    end
  end
end

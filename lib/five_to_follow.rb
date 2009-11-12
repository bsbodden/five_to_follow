require 'rubygems'
require 'trellis'
require 'grackle'
require 'hits'

include Trellis

module FiveToFollow
  
  class FiveToFollowApp < Application
    home :search
    
    map_static ['/styles', '/images']
  end

  class Search < Page
    pages :search_results
    persistent :results
    
    def initialize
      super
      @client = Grackle::Client.new(:auth=>{:type=>:basic,:username=>'bsbodden',:password=>'valencia'})
    end
    
    def on_submit_from_search
      term = params[:search_query]
      logger.info "searching with term #{term}"
      response = @client[:v1].search? :q=> term

      # graph of tweets
      graph = Hits::Graph.new
      
      # add nodes to graph
      response.results.each do |tweet|
        graph.add_edge(tweet.from_user, tweet.to_user) if tweet.to_user
        tweet.text.scan(/[^\A]@([A-Za-z0-9_]+)/).flatten.each do |to|
          graph.add_edge(tweet.from_user, to) if tweet.from_user != to
        end
      end
      
      logger.info "graph for #{term} => \n #{graph}"
      
      # calculate HITS on graph
      hits = Hits::Hits.new(graph)
      hits.compute_hits

      @results = ''
      @results << hits.top_authority_scores.join(',')
      @results << ','
      @results << hits.top_hub_scores.join(',')
      
      logger.info "results for #{term} are #{@results}"
      
      self
    end
  end

  class Login < Page
    pages :settings

    template do
      xhtml_strict {
        head {
          title "Login to FiveToFollow"
        }
        body {
          h1 "Login Fields go here!"
        }
      }
    end
  end

  class Settings < Page

    template do
      xhtml_strict {
        head {
          title "Account Settings"
        }
        body {
          h1 "Account Settings Fields go here!"
        }
      }
    end
  end

  if __FILE__ == $PROGRAM_NAME
    web_app = FiveToFollowApp.new
    web_app.start 3000
  end
end

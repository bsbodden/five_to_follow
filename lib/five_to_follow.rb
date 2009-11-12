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
      term = params[:search_query] || ""
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
    
    template do
      tag!(:html,
           :xmlns => "http://www.w3.org/1999/xhtml",
           "xml:lang" => "en",
           :lang => "en",
           "xmlns:trellis" => "http://trellisframework.org/schema/trellis_1_0_0.xsd") {
        head {
          title "Welcome to FiveToFollow"
          link :rel => "stylesheet", :href => "styles/blueprint/screen.css", :type => "text/css", :media => "screen, projection"
          link :rel => "stylesheet", :href => "styles/blueprint/print.css", :type => "text/css", :media => "print"
          link :rel => "stylesheet", :href => "styles/five_to_follow.css", :type => "text/css", :media => "screen, projection"          
        }
        body {          
          div(:class => "container") {
            # <!-- ====== -->
            # <!-- Header -->
            # <!-- ====== -->   
            div.header!(:class => "span-24") {
              div.logo!(:class => "prepend-6 span-12") {
                h1 {
                  a(:href => ".", :title => "Five To Follow") {
                    text %[Five To Follow :: The Easiest Way to Find People to Follow on Twitter!]
                  }
                }
              }
            } 
    
            # <!-- ======= -->
            # <!-- Content -->
            # <!-- ======= -->
            div.content!(:class => "span-24") {
              div(:class => "prepend-5 span-14") {
                h2 "Find People Interested In..."
              }
              div(:class => "prepend-3 span-18") {
                text %[<trellis:form tid="search" method="post">] 
                  div(:class => "span-14") {
                    text %[<trellis:text_field tid="query" id="query" class="span-14"/>]
                  }
                  div(:class => "span-4 last") {
                    text %[<trellis:button tid="submit" id="go" title="Go!" type="submit">Go!</trellis:button>]
                  }
                text %[</trellis:form>]
              }
              div.results!(:class => "span-24") {
                div.user_list!(:class => "span-24") {
                 text %[<trellis:value name="results"/>]
                }
                div.follow_or_not!(:class => "prepend-5 span-14") {
                  div(:class => "span-7") {
                    button(:id => "follow", :name => "follow", :title => "Follow", :type => "submit") { "Follow" }
                  }
                  div(:class => "span-7 last") {
                    button(:id => "dont_follow", :name => "dont_follow", :title => "No, Thanks!", :type => "submit") { "No, Thanks!" }
                  }
                }   
              }
            }
            # <!-- ====== -->
            # <!-- Footer -->
            # <!-- ====== -->
            div.footer!(:class => "span-24") {
            }
          }
        }
      }
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

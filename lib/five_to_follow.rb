$: << File.dirname(__FILE__) unless $:.include? File.dirname(__FILE__)

require 'rubygems'
require 'trellis'
require 'grackle'
require 'hits'
require 'ostruct'
require 'methodchain'
require 'net/http'
require 'twitterland'
require 'twitter_utils'

include Trellis
  
module FiveToFollow
  
  class FiveToFollowApp < Application
    home :search
    
    directories = ['/styles', '/javascript', '/images', '/html']
    if ENV['RACK_ENV'] == 'production'
      map_static directories, 'html'
    else
      map_static directories
      logger.level = DEBUG
    end
  end

  class Search < Page
    persistent :results
    
    def initialize
      super
      @twitter_client = TwitterClient.new
      @twitter_client.logger = logger
    end
    
    def on_submit_from_search
      term = params[:search_query] || ""
      logger.info "searching with term #{term}"
      response = @twitter_client.search(term)

      # graph of tweets
      graph = Hits::Graph.new
      
      while response.next_page
        logger.info "processing result page #{response.page}"
        # add directed edges to graph
        response.results.each do |tweet|
          # TODO: add an edge to a vertex representing the topic itself (query)
          
          # add an edge if this is an explicitly directy tweet (has a to_user)
          origin = @twitter_client.get_user(tweet.from_user, tweet)
          destination = @twitter_client.get_user(tweet.to_user, tweet) if tweet.to_user
          graph.add_edge(origin, destination) if destination
         
          # iterate over all mentions (@user) in hte tweet text
          tweet.text.scan(/[^\A]@([A-Za-z0-9_]+)/).flatten.each do |to|
            # if it is not a self mention and it is a valid user add an edge
            if tweet.from_user != to
              destination = @twitter_client.get_user(to, tweet)
              graph.add_edge(origin, destination) if destination
            end
          end # each mention
        end # each response
        
        # get the next page
        response = @twitter_client.next_page(response)
      end
      
      logger.debug "graph for #{term} => \n #{graph}"
      
      # calculate HITS on graph
      hits = Hits::Hits.new(graph)
      hits.compute_hits

      @results = ''
      hits.top_authority_scores.each do |hit|
        html = %[<a href="http://twitter.com/#{hit.user}" title="#{hit.user}"><img src="#{hit.image || "/images/default_profile_normal.png"}" width="100%" /></a>]
        @results << html
      end
            
      logger.debug "top 20 authorities for #{term} are #{hits.top_authority_scores(20).collect{|hit| hit.user}.join(', ')}"
      logger.debug "top 20 hubs for #{term} are #{hits.top_hub_scores(20).collect{|hit| hit.user}.join(', ')}"
       
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
          
          script(:type => "text/javascript", :src => "javascript/jquery.js") {}
          script(:type => "text/javascript", :src => "javascript/interface/iutil.js") {}
          script(:type => "text/javascript", :src => "javascript/interface/carousel.js") {}
        }
        body {          
          div(:class => "container") {  
            div.header!(:class => "span-24") {
              div.logo!(:class => "prepend-6 span-12") {
                h1 {
                  a(:href => ".", :title => "Five To Follow") {
                    text %[Five To Follow :: The Easiest Way to Find People to Follow on Twitter!]
                  }
                }
              }
            } 
    
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
                
                div.carousel!(:class => "prepend-7 span-10") {
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

            div.footer!(:class => "span-24") {
              iframe(:src => "html/featured_users.html", :class => "prepend-3 span-18", :width => "100%", :scrolling => "no") {
                a(:href => "http://featuredusers.com/referral/pub-831/", :title => "Featured Users", :class => "prepend-6 span-12") {
                  img(:src => "images/featured_users.jpg") 
                }
              }
            }
          }
          script(:type => "text/javascript", :charset => "utf-8") do 
            %[
            // jquery carousel
            window.onload = function() {
              $('#carousel').Carousel({
                itemWidth: 48,
              	itemHeight: 48,
              	itemMinWidth: 48,
              	items: 'a',
              	reflections: .2,
              	rotationSpeed: 1.0
            });}              
            ]      
          end
          script(:type => "text/javascript", :src => "http://s3.amazonaws.com/getsatisfaction.com/javascripts/feedback-v2.js")
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
    web_app.start 3005
  end
end

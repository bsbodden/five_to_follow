$: << File.dirname(__FILE__) unless $:.include? File.dirname(__FILE__)

require 'rubygems'
require 'trellis'
require 'grackle'
require 'hits'
require 'ostruct'
require 'methodchain'
require 'net/http'
require 'twitterland'
require 'facets/duration'
require 'facets/date'
require 'twitter_utils'
require 'db'

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
      @results = ''
      now = DateTime.now
      
      query = Model::Query.first(:terms => term)
      
      unless query && (query.last_evaluation > now.ago(Duration::DAY))
        unless query # query not found in the database, create it
          query = Model::Query.new(:terms => term, :version => 1, :last_request => now, :last_evaluation => now, :hits => 1)
        else # the query results are too old, reevaluate and update access info
          query.last_request = now
          query.last_evaluation = now 
          query.hits = query.hits + 1
        end
        query.save
        
        # search twitter for the terms
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

        # create response html for carousel
        hits.top_authority_scores.each do |hit|
          html = %[<a href="http://twitter.com/#{hit.user}" title="#{hit.user}"><img src="#{hit.image || "/images/default_profile_normal.png"}" width="100%" /></a>]
          @results << html
        end
        
        # save the authority scores for the query 
        score = 1
        hits.top_authority_scores(20).each do |hit| 
          logger.debug "saving #{hit} to the database as authority"
          authority_score = Model::AuthorityScore.new(:twitter_id => hit.user, :score => score, :query => query, :version => query.version)
          score = score + 1
          authority_score.save
        end
        
        # save the hub scores for the query
        score = 1
        hits.top_hub_scores(20).each do |hit| 
          logger.debug "saving #{hit} to the database as hub"
          hub_score = Model::HubScore.new(:twitter_id => hit.user, :score => score, :query => query, :version => query.version)
          score = score + 1
          hub_score.save
        end
        
        # save the users in the graph
        graph.each_vertex do |twitter_user|
          logger.debug "saving #{twitter_user.user}, #{twitter_user.image}"
          profile = Model::Profile.first(:twitter_id => twitter_user.user)
          unless profile
            profile = Model::Profile.new(:twitter_id => twitter_user.user, 
                                         :image => twitter_user.image, 
                                         :confirmed => (!twitter_user.image.nil? && !twitter_user.image.empty?))
            profile.save
          else
            # update the user avatar
            if profile.image.nil? && !twitter_user.image.nil? && !twitter_user.image.empty?
              profile.image = twitter_user.image
              profile.save
            end
          end
        end
        
        logger.debug "top 20 authorities for #{term} are #{hits.top_authority_scores(20).collect{|hit| hit.user}.join(', ')}"
        logger.debug "top 20 hubs for #{term} are #{hits.top_hub_scores(20).collect{|hit| hit.user}.join(', ')}"
      else # return the results from the database
        logger.debug "retrieving cached results from database"
        query.top_authority_scores.each do |hit|
          html = %[<a href="http://twitter.com/#{hit.twitter_id}" title="#{hit.twitter_id}"><img src="#{hit.profile.image || "/images/default_profile_normal.png"}" width="100%" /></a>]
          @results << html
        end
        # update the query access information
        query.last_request = now
        query.hits = query.hits + 1
        query.save
      end
            
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
          text %[<!--[if IE]>]
          link :rel => "stylesheet", :href => "styles/blueprint/ie.css", :type => "text/css", :media => "screen, projection"
          text %[<![endif]-->]
          link :rel => "stylesheet", :href => "styles/five_to_follow.css", :type => "text/css", :media => "screen, projection" 
          link :rel => "shortcut icon", :href => "images/favicon.ico", :type => "image/x-icon"
          
          script(:type => "text/javascript", :src => "javascript/jquery.js") {}
          script(:type => "text/javascript", :src => "javascript/interface/iutil.js") {}
          script(:type => "text/javascript", :src => "javascript/interface/carousel.js") {}
        }
        body {          
          div(:class => "container") {  
            div.header!(:class => "span-24") {
              div.beta! {}
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
                  div(:class => "span-18") {
                    text %[<trellis:text_field tid="query" id="query" class="span-14" tabindex="1"/>]
                    text %[<trellis:button tid="submit" id="search" title="Go!" type="submit" tabindex="2">Search</trellis:button>]
                  }
                text %[</trellis:form>]
              }
              div.results!(:class => "span-24") {
                text %[<trellis:unless test="results.nil?">]
                div.carousel!(:class => "prepend-7 span-10 last") {
                    text %[<trellis:value name="results"/>]
                }
                text %[</trellis:unless>]
                
                text %[<trellis:if test="results.nil?">]
                div(:class => "prepend-5 span-14 last") {
                  img(:src => "images/quick_about.png")
                }
                text %[</trellis:if>]   
              }
            }

            div.footer!(:class => "span-24") {
              
              iframe(:src => "html/adbrite.html", :class => "prepend-2 span-22", :width => "100%", :scrolling => "no")

              # ul(:class => "font-upper") {
              #   Page.subclasses.values.each { |page|
              #     li{ 
              #       text %[<trellis:page_link tpage="#{page.name}">#{page.name}</trellis:page_link>]
              #     }
              #   }
              # }
              
              p(:class => "copyright") { 
                text("&copy; 2009 - FiveToFollow is an ")
                a(:href => "http://www.integrallis.com") { "Integrallis" }
                text(" company") 
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

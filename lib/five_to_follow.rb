require 'rubygems'
require 'trellis'
require 'grackle'
require 'rgl/dot'
require 'rgl/adjacency'
require 'rgl/bidirectional'


include Trellis

module Hits

  class Graph
    attr_reader :graph

    def initialize
      @graph = RGL::DirectedAdjacencyGraph.new
      @in_links = {}
      @edge_weights = {}
    end

    def add_edge(from, to, weight = 1.0)
      # add the edge to the internal graph representation
      @graph.add_edge(from, to)
      # keep a list of
      @in_links[to] ||= []
      @in_links[to] << from unless @in_links[to].include? from
      @edge_weights[[to, from]] = weight
    end

    def in_links(vertex)
      @in_links[vertex]
    end

    def out_links(vertex)
      @graph.adjacent_vertices(vertex)
    end

    def each_vertex(&b)
      @graph.each_vertex(&b)
    end

    def weight(to, from)
      @edge_weights[[to, from]]
    end

    def to_s
      @graph.edges.to_a.to_s
    end

  end

  class Hits

    def initialize(graph)
      @graph = graph
      @hub_scores = {}
      @authority_scores = {}
      @graph.each_vertex do |vertex|
        @hub_scores[vertex] = 1.0
        @authority_scores[vertex] = 1.0
      end
    end

    def compute_hits(iterations = 25)
      (1..iterations).each do
        @graph.each_vertex do |vertex|
          authority_score = @graph.in_links(vertex).inject(0.0) { |sum, vertex| sum + @hub_scores[vertex] } if @graph.in_links(vertex)
          hub_score = @graph.out_links(vertex).inject(0.0) { |sum, vertex| sum + @authority_scores[vertex] } if @graph.out_links(vertex)
          @authority_scores[vertex] = authority_score || 0.0
          @hub_scores[vertex] = hub_score || 0.0
        end
      end
    end

    def top_hub_scores(how_many=50)
      @hub_scores.sort_by { |k,v| v }.collect { |v| v[0] }.reverse.first(how_many)
    end

    def top_authority_scores(how_many=50)
      @authority_scores.sort_by { |k,v| v }.collect { |v| v[0] }.reverse.first(how_many)
    end

  end
end

module FiveToFollow
  
  class FiveToFollowApp < Application
    home :search
  end

  class Search < Page
    pages :search_results
    persistent :results
    
    def initialize
      super
      @client = Grackle::Client.new(:auth=>{:type=>:basic,:username=>'bsbodden',:password=>'valencia'})
    end
    
    def on_submit_from_search
      term = params[:search_term]
      logger.info "searching with term #{term}"
      response = @client[:v1].search? :q=> term

      # graph of tweets
      graph = Hits::Graph.new
      
      # add nodes to graph
      response.results.each do |tweet|
        graph.add_edge(tweet.from_user, tweet.to_user) if tweet.to_user
        tweet.text.scan(/[^\A]@([A-Za-z0-9_]+)/).flatten.each do |to|
          graph.add_edge(tweet.from_user, to)
        end
      end
      
      # calculate HITS on graph
      hits = Hits::Hits.new(graph)
      hits.compute_hits

      @results = ''
      @results << hits.top_authority_scores.join(',')
      @results << hits.top_hub_scores.join(',')
      
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
        }
        body {
          h1 "Enter a search term to find folks to follow..."
          text %[<trellis:form tid="search" method="post">]
          p {
            text %[<trellis:text_field tid="term"/>]
            text %[<trellis:submit tid="title" value="Search"/>]
          }
          text %[</trellis:form>]
          p {
            text %[<trellis:value name="results"/>]
          }
        }
      }
    end
  end

  class SearchResults < Page
    pages :search

    template do
      xhtml_strict {
        head {
          title "Twitter Users Found..."
        }
        body {
          h1 "For the term 'blah' we found"
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

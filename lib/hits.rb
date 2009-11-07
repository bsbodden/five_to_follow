require 'rgl/dot'
require 'rgl/adjacency'
require 'rgl/bidirectional'

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
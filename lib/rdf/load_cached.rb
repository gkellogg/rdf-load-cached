require 'rdf'
require 'sparql/service_description'

module RDF
  ##
  # RDF::LoadCached provides a mixin to use with repositories for maintaining the provinance
  # and cachability of loaded data. This allows implementations to freely use `#load`
  # to load data that may already be present in the repository, using HTTP cache control
  # semantics to determine if the data actually needs to be re-loaded, or may continue
  # to use existing statements.
  #
  # To use, extend repository with RDF::LoadCached and initialize `dataset` with
  # RDF::Void::Dataset instance to associate with this repository. The `dataset`
  # will be used to manage provenance information on loaded graphs.
  #
  # == Limitations
  #
  # A Repository may have only a single loaded document as the default graph.
  #
  # @example
  #
  #   ds = RDF::Void.dataset[dataset-uri]  # dataset-uri is URI where dataset is published
  #   r = RDF::Repository.new
  #   r.dataset = v.dataset[dataset_uri]
  #   r.load(default-graph-uri)
  #   r.load(named-graph-uri, :context => named-graph-uri)
  # 
  module LoadCached
    ##
    # Handle to the dataset description for this repository.
    #
    # @attr [RDF::Void::Dataset] dataset
    #   Dataset instance used for recording information about this repository.
    attr_accessor :dataset
    
    ##
    # Loads RDF statements from the given file or URL into `self`.
    #
    # Maintains references to loaded files in the default or defined
    # context of the current Mutable object.
    #
    # Specifying a :context option to load will create a named-graph. Typically, the :context
    # will be the same as the filename (URI) being loaded.
    # 
    # Loading a file without a :context will create a defaultGraph instance. Note that a dataset
    # may have more than one defaultGraph, so that the set of triples not having a context
    # will be the union of the triples from each sd:defaultGraph.
    #
    # A request to load a graph uses the following process:
    # 
    # 1. If an entry exists, use HTTP properties to determine if a conditional GET
    #    operation is required.
    # 2. If a conditional GET is required, perform the get. If a status 304 (Not Modified) is
    #    returned, continue to use the existing dataset.
    # 3. If the filename is loaded into the default graph, remove all triples in the default
    #    graph and cause a reload of all graphs within the default graph.
    # 4. Otherwise, if the filename is loaded into a named graph, remove all triples having
    #    the associated context, and load the file using the sd:name as the context.
    # 
    # @param  [String, #to_s]          filename
    # @param  [Hash{Symbol => Object}] options
    # @option options [RDF::URI] :context
    #   Context applied to loaded triples, used to associate loaded files with named graphs.
    # @option options [RDF::URI] :dataset (RDF::Node.new)
    #   URI of dataset, describing loaded files.
    # @option options [RDF::URI] :override_cache_control (true)
    #   Override resource cache-control directives when reading or updating and cache
    #   the graph indefinitely. This is useful for graphs that are known to be stable,
    #   and HTTP headers are not generated to enable caching otherwise.
    # @option options [RDF::Mutable] :dataset_graph (self)
    #   Graph to store Dataset meta information used for managing graphs.
    #   Defaults to the default context of this queryable instance.
    # @return [void]
    #
    def load(filename, options = {})
      
      # See if a dataset definition (with appropriate context) already
      # exists for filename
      graph = dataset.find(filename, options[:context])
      graph ||= dataset.new_graph(filename, options[:context])

      # Remove any existing statements.
      delete(nil, nil, nil, :context => options[:context] || false)

      # Perform conditional load of the graph source if it is out-of-date
      if graph.expired? && stream = graph.load
        RDF::Reader.for(:content_type => stream.content_type).new(stream, :base_uri => filename) do |reader|
          if options[:context]
            statements = []
            reader.each_statement do |statement|
              statement.context = options[:context]
              statements << statement
            end
            insert_statements(statements)
          else
            insert_statements(reader)
          end
        end
      end
    
      # Update access time of graph
      graph.response_time = DateTime.now
      graph.save!
    end
    
    ##
    # Spira representation of Service Description Dataset
    # representing one or more default- and named-graphs.
    class Dataset < Spira::Base
      type SD.Dataset
      property :title,          :predicate => DC.title
      property :description,    :predicate => DC.description
      has_many :default_graphs, :predicate => SD.defaultGraph, :type => SD.Graph
      has_many :named_graphs,   :predicate => SD.namedGraph,   :type => SD.Graph
      
      ##
      # Retrieve the Dataset from within queryable
      def self.get(queryable)
        Spira.add_repository(:default => queryable)
        Dataset.each.to_a.first
      end
      
      ##
      # Find a graph having the specified source
      # @param [RDF::URI] source
      # @return [RDF::LoadCached::Graph]
      def find(source, name)
        if name
          named_graphs.detect {|g| g.source == source && g.name == name}
        else
          default_graphs.detect {|g| g.source == source}
      end
      
      ##
      # Create a new graph, if it has a context, add it to named_graphs, default_graphs otherwise
      def new_graph(source, name)
        g = RDF::Node.new.as(Graph)
        g.source = source
        g.name = name
        g.save!
        (name ? named_graphs : default_graphs) << g
        g
      end
    end
    
    class Graph < Dataset
      type SD.Graph
      property :name,           :predicate => SD.name
      property :source,         :predicate => DC.source
      property :date,           :predicate => DC.date
      property :modified,       :predicate => DC.modified
      property :max_age,        :predicate => CACHE.maxAge
      property :expires,        :predicate => CACHE.expires
      property :etag,           :predicate => CACHE.etag
      
      ##
      # Return a stream for the graph unless caching indicates that it is not required.
      #
      # @return [IO]
      #   Return stream (or nil), with a #content_type method attached indicating the mime-type of the result
      def read
      end
      
      # Is cached content fresh?
      # @return [Boolean]
      def fresh?
      end
    end
  end
end

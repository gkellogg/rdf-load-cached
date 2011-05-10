# RDF::LoadCached

HTTP Cache semantics for loaded graphs for RDF.rb.

## Description

This plugin modifies the behavior of RDF::Mutable#load to maintain metadata
about loaded graphs to enable HTTP content caching.

Details are stored using the [Void][] and [SPARQL Service Description][SSD] vocabularies.

Mutable objects (such as RDF::Resource) including this module will have
Dataset information asserted similar to the following:

  @prefix sd: <http://www.w3.org/ns/sparql-service-description#> .
  @prefix void: <http://rdfs.org/ns/void#> .
  @prefix cache: <http://rdf.rubygems.org/cache#>

  :DataSet a sd:Dataset;
    sd:defaultGraph [
      a sd:Graph, void:Dataset;
      dc:source <filename>; # Used as source for the sd:Graph resource as well as the graph origin URI.
      dc:date "1994-11-15T08:12:31Z";                             # HTTP Date field
      dc:modified "1994-11-15T12:45:65Z";                         # HTTP Last-Modified
      cache:cachable true;                                        # From public/private/no-cache/no-store
      cache:age "3600"^^%xsd:integer;                             # HTTP Age: 3600
      cache:maxAge "3600"^^%xsd:integer;                          # HTTP Cache-Control: max-age="3600"
      cache:etag "737060cd8c284d8af7ad3082f209582d"^^xsd:string;  # HTTP ETag
      cache:expires "1994-12-01T16:00:00Z"^^xsd:dateTime;         # HTTP Expires
    ];
    sd:namedGraph [
      a sd:Graph, void:Dataset;
      dc:source <filename>;
      cache:etag "737060cd8c284d8af7ad3082f209582d"^^xsd:string;
      sd:name <context-uri>;                                      # Name indicates context of dataset
    ] .

sd:defaultGraph and sd:namedGraph will use the filename as the
object, and can be used to update the dataset as appropriate.

A service using this object as a SPARQL dataset may supplement
information stored as part of the graph descriptions with other service
information such as sd:uri describing an sd:Service, and other appropriate properties.

Within an RDF::Queryable instance, triples from sd:defaultGraph datasets are merged
together. Triples from sd:namedGraph datasets are kept within distinct contexts (i.e.,
the sd:name is used as a :context entry for each RDF::Statement).

## Documentation

* {RDF::LoadCached}

## Dependencies

* [Ruby](http://ruby-lang.org/) (>= 1.8.7) or (>= 1.8.1 with [Backports][])
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.1)

## Mailing List

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Author

* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>

## Contributors

Refer to the accompanying {file:CREDITS} file.

## Contributing

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you.

## License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

Portions of tests are derived from [W3C DAWG tests](http://www.w3.org/2001/sw/DataAccess/tests/) and have [other licensing terms](http://www.w3.org/2001/sw/DataAccess/tests/data-r2/LICENSE).

[Ruby]:     http://ruby-lang.org/
[RDF]:      http://www.w3.org/RDF/
[PDD]:      http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
[Void]:     http://vocab.deri.ie/void
[YARD]:     http://yardoc.org/
[YARD-GS]:  http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:      http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html

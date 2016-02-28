# TODO

* Update checkstyle configuration so that supressions.xml can be omitted if it is the default variant.
* Rework publish flag so it defaults to false
* Add templates for each project that automagically adds relevant aspects. i.e.
    - IDEA project facets
    - paths to source code analysis
    - publish flags
* Default configuration of :default dbt database. i.e.
    - Auto add `database.search_dirs = %w(database/generated database)`  or `database.search_dirs = %w(database)` depending on presences of domgen
    - Auto add `database.enable_domgen` if domgen present

# TODO

* Add deps list for jett
* Consider updating template such that all services move into a module named "services", the remaining gunk
  such as webapp etc stay in server? Perhaps this could be a mechanism via which wars and libraries differ.
* Add checkstyle check to ensure none of the "THIS FILE IS GENERATED" style messages occur
  in source
* Move css_lint and scss_lint extensions from sauron into buildr_plus
* The all_in_one role has significant overlap with model, server and container roles. Should we consider
  extracting commonality somehow?

# TODO

* Add deps list for jett
* Consider updating template such that all services move into a module named "services", the remaining gunk
  such as webapp etc stay in server? Perhaps this could be a mechanism via which wars and libraries differ.
* Add checkstyle check to ensure none of the "THIS FILE IS GENERATED" style messages occur
  in source
* Move css_lint and scss_lint extensions from sauron into buildr_plus
* The all_in_one role has significant overlap with model, server and container roles. Should we consider
  extracting commonality somehow?

## Major Refactor

Buildr_plus should be refactored to be based on reality-model. As part of this refactoring the following
actions should be taken:

* Role should become a model object.
  - The domgen facet on the role should list the generators run by role. (And this is derived from facets)
  - The resgen facet on the role should list the generators run by role. (And this is derived from facets)
  - The dependencies facet on the role should list the dependencies required by role. (And this is derived from facets)
  - The buildr facet on the role can declare additional custom actions.
* Roles should declare dependencies. Some dependencies are merely optional. If present they will be linked to.
  Some dependencies are required and it is an error if they are not present. Finally some are externalizable
  and if they exist will be linked to and if they do not exist then the role will be merged into the current role.

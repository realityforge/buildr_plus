# TODO

* Add deps list for jett
* Default publish role to false, then use roles to enabled based on features such as:
  - is deployable feature enabled?
  - is library feature enabled?
  - is gwt library feature enabled?
  - is soap-client project
* Consider updating template such that all services move into a module named "services", the remaining gunk
  such as webapp etc stay in server?
* Add checkstyle check to ensure none of the "THIS FILE IS GENERATED" style messages occur
  in source
* Add in role for rails apps
* The all_in_one role has significant overlap with model, server and container roles. Should we consider
  extracting commonality somehow?

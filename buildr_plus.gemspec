# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name               = %q{buildr_plus}
  s.version            = '1.0.0'
  s.platform           = Gem::Platform::RUBY

  s.authors            = ['Peter Donald']
  s.email              = %q{peter@realityforge.org}

  s.homepage           = %q{https://github.com/realityforge/buildr_plus}
  s.summary            = %q{A set of simple defaults for buildr.}
  s.description        = %q{A set of simple defaults for buildr.}

  s.rubyforge_project  = %q{buildr_plus}

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.default_executable = []
  s.require_paths      = %w(lib)

  s.has_rdoc           = false
  s.rdoc_options       = %w(--line-numbers --inline-source --title buildr_plus)

  s.add_dependency 'reality-core', '>= 1.6.0'
  s.add_dependency 'reality-naming', '>= 1.8.0'
end

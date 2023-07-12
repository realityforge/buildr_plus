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

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths      = %w(lib)

  s.rdoc_options       = %w(--line-numbers --inline-source --title buildr_plus)

  s.add_dependency 'reality-core', '>= 1.8.0'
  s.add_dependency 'reality-naming', '>= 1.13.0'
  s.add_dependency 'zapwhite', '= 2.20.0'
end

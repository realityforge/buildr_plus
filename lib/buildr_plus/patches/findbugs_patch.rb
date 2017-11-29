expected_versions = %w(1.5.3)
unless expected_versions.include?(Buildr::VERSION.to_s)
  raise "Patch should no longer be required unless Buildr versions are #{expected_versions.join(', ')} but actual version is #{Buildr::VERSION}"
end

module Buildr::Findbugs
  class << self
    def dependencies
      %w(
          com.google.code.findbugs:findbugs:jar:3.0.1
          com.google.code.findbugs:jFormatString:jar:3.0.0
          com.google.code.findbugs:bcel-findbugs:jar:6.0
          com.google.code.findbugs:annotations:jar:3.0.1
          org.ow2.asm:asm-debug-all:jar:5.0.2
          commons-lang:commons-lang:jar:2.6
          dom4j:dom4j:jar:1.6.1
          jaxen:jaxen:jar:1.1.6
        )
    end
  end
end

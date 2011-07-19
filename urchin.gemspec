require "#{File.expand_path(File.dirname(__FILE__))}/version"

spec = Gem::Specification.new do |s|
  s.name = "urchin"
  s.version = Urchin::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "A Unix shell for Ruby programmers"
  s.description = "Inspired by and trying to cherry-pick the best bits from Bash/Zsh and Ruby."

  s.required_ruby_version = ">= 1.8.6"

  s.add_development_dependency "rake"

  s.files = Dir.glob("{lib,builtins,completion,test}/**/*.rb") + %w( README COPYING Rakefile environment.rb )

  s.require_path = "lib"
  s.executables = [ "urchin" ]

  s.rdoc_options << "--main"  << "README" << "--title" << "Urchin - Documentation"
  s.extra_rdoc_files = %w( README COPYING )

  s.homepage = "http://spakman.github.com/urchin/"
  s.licenses = [ "GPLv3" ]
  s.authors = [ "Mark Somerville" ]
  s.email = [ "mark@scottishclimbs.com" ]
end
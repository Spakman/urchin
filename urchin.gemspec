require "#{File.expand_path(File.dirname(__FILE__))}/version"

spec = Gem::Specification.new do |s|
  s.name = "urchin"
  s.version = Urchin::VERSION
  s.platform = Gem::Platform::RUBY
  s.summary = "A Unix shell for Ruby programmers"
  s.description = "Inspired by and trying to cherry-pick the best bits from Bash/Zsh and Ruby."

  s.required_ruby_version = ">= 1.9.3"

  s.add_development_dependency "rake"

  s.files = Dir.glob("{lib,builtins,completion,bin,test}/**/*.rb") + %w( README COPYING Rakefile environment.rb boot.rb version.rb )

  s.require_path = "lib"
  s.executables = [ "urchin" ]

  s.rdoc_options << "--main"  << "README" << "--title" << "Urchin - Documentation"
  s.extra_rdoc_files = %w( README COPYING )

  s.homepage = "http://spakman.github.com/urchin/"
  s.licenses = [ "GPLv3" ]
  s.authors = [ "Mark Somerville" ]
  s.email = [ "mark@scottishclimbs.com" ]

  s.add_dependency("rb-readline", ">= 0.5.0")

  s.post_install_message = <<POST_INSTALL
*******************************************************************************

  If you have checked that it is stable enough on your system and want to use
  Urchin as your login shell, these steps are required:

    (as root) $ echo /path/to/urchin >> /etc/shells
    (as user) $ chsh -s /path/to/urchin

*******************************************************************************
POST_INSTALL
end

Gem::Specification.new do |spec|

  spec.name        = 'raidis'
  spec.version     = '1.0.0'
  spec.date        = '2014-01-10'
  spec.summary     = 'Yet another failover wrapper around Redis.'
  spec.description = 'See https://github.com/bukowskis/raidis'
  spec.authors     = %w{ bukowskis }
  spec.homepage    = 'https://github.com/bukowskis/raidis'

  spec.files       = Dir['Rakefile', '{bin,lib,man}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")

  spec.add_dependency 'redis-namespace'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'rb-fsevent'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'rb-readline'

end

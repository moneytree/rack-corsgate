Gem::Specification.new do |spec|
  spec.name        = 'rack-corsgate'
  spec.version     = '0.2.0'
  spec.date        = '2018-09-13'
  spec.summary     = 'Modern CORS-based CSRF-protection for Rack apps'
  spec.description = 'This middleware builds on top of rack-cors, using CORS rules to mitigate CSRF-attacks.'
  spec.authors     = ['Ron Korving']
  spec.email       = 'rkorving@moneytree.jp'
  spec.files       = [
    'lib/rack-corsgate.rb',
    'lib/classes/cors_gate.rb',
    'lib/classes/cors_gate_origin_processor.rb'
  ]
  spec.homepage    = 'https://github.com/moneytree/rack-corsgate'
  spec.license     = 'MIT'

  spec.add_development_dependency 'rack-cors', '~> 1.0.2'
  spec.add_development_dependency 'rspec-rails', '~> 3.8'
  spec.add_development_dependency 'rack-test', '~> 1.1'
end

# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'sidekiq/history/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-history'
  spec.version       = Sidekiq::History::VERSION
  spec.authors       = ['Russ Smith']
  spec.email         = ['russ@bashme.org']
  spec.description   = 'History for sidekiq jobs.'
  spec.summary       = 'History for sidekiq jobs.'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = ::Dir['{lib,web}/**/*']
  spec.executables   = []
  spec.require_paths = %w[lib]

  spec.add_dependency 'sidekiq', '>= 6.5'

  spec.add_development_dependency 'bundler', '> 1.16'
  spec.add_development_dependency 'rake', '> 10.0'
  spec.add_development_dependency 'rubocop', '~> 1.30'

  # I'm not pushing to RubyGems but rubocop likes this
  spec.metadata['rubygems_mfa_required'] = 'true'
end

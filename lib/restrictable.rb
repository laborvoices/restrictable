require 'restrictable/concerns/restricted_user.rb'
require 'restrictable/concerns/controller.rb'
require 'restrictable/concerns/model.rb'

module Restrictable
  mattr_accessor  :config
end

Restrictable.config = YAML.load(File.read(File.expand_path('config/restrictable.yml',Rails.root)))


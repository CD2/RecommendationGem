require_dependency './lib/q/execute.rb'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

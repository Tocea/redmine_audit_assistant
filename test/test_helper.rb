# Coveralls configuration
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = Coveralls::SimpleCov::Formatter
SimpleCov.start do
   add_filter do |source_file|
     !source_file.filename.include? "/plugins/"
   end
end
Coveralls.wear!('rails')

# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')

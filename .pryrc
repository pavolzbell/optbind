$LOAD_PATH.unshift File.expand_path '../lib', __FILE__

Dir[File.expand_path '../lib/*.rb', __FILE__].each { |f| require_relative f }

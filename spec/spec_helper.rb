$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'ostruct'
require 'optbind'

OptParse = OptionParser unless defined? OptParse

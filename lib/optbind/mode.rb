require 'optbind'

class OptionBinder
  def order(*argv, &blk)
    order! argv.dup.flatten, &blk
  end

  def order!(argv = parser.default_argv, &blk)
    parse_args! @parser.order! argv, &blk
  end

  def permute(*argv)
    permute! argv.dup.flatten
  end

  def permute!(argv = parser.default_argv)
    parse_args! @parser.permute! argv
  end

  module Arguable
    def order(&blk)
      binder.order self, &blk
    end

    def order!(&blk)
      binder.order! self, &blk
    end

    def permute
      binder.permute self
    end

    def permute!
      binder.permute! self
    end
  end
end

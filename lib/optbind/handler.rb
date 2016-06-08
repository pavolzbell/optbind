require 'optbind'

module OptionBinder::Handler
  def matched_by(p)
    -> (v) { p =~ v.to_s ? v : raise(OptionParser::InvalidArgument, v) if v }
  end

  alias_method :matches, :matched_by

  def included_in(*a)
    -> (v) { a[0].include? v ? v : raise(OptionParser::InvalidArgument, v) if v } if a[0].is_a? Range
    -> (v) { a.flatten.include?(v) ? v : raise(OptionParser::InvalidArgument, v) if v }
  end

  alias_method :in, :included_in

  def listed_as(t)
    -> (v) do
      begin
        b, p = nil, OptionParser.new.on(:REQUIRED, '--0', t, &-> (i) { b = i })
        (v.is_a?(Array) ? v : v.to_s.split(/,/)).map { |i| p.parse! %W(--0=#{i}) and b } if v
      rescue OptionParser::InvalidArgument
        raise $!.tap { |e| e.args[0] = e.args[0].sub(/\A--\d+=/, '') }
      end
    end
  end

  alias_method :lists, :listed_as
end

OptionBinder.prepend OptionBinder::Handler

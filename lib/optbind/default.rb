require 'optbind'

class OptionBinder
  alias_method :several_variants_without_default_description, :several_variants

  def several_variants(*opts, &handler)
    opts, handler, bound, variable, default = several_variants_without_default_description *opts, &handler
    desc = opts.find { |o| o.is_a?(String) && o !~ /\A\s*[-=\[]/ }.tap { |d| opts.delete d if d }

    if !default.nil? && (!default.respond_to?(:empty?) || !default.empty?)
      desc = "#{desc == nil || desc.empty? ? 'D' : "#{desc}, d"}efault #{[default] * ','}"
    end

    opts << desc if desc && !desc.empty?
    return opts, handler, bound, variable, default
  end

  private :several_variants
end

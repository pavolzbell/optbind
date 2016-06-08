# TODOS

  - make a way to include all exts at once like require 'optbind/all'
  - test against special cases for multiple args like 'a <ids...>' with '--x 1'
  - add optbind/defaults from extise as separate package, required on demand

  - add support for arrays of int -> <x:Array:Integer> and <x:Integer>... 
  - add support for ranges on `OptionParser` level

  - `Switch#parser_opts_from_string` - support regexps with options, like `=<name:/[a-z]/i>`
  - `Switch#parser_opts_from_string` - support ranges, like `=<indent:0..8>`

  - make optional extensions for `OptionParser` monkey-patching `make_switch` to support hash-or-string-exclusive arguments 

# IDEAS

gems:
  optparse-struct   struct/hash-only API       #make_switch_from_struct, #make_switch_from_hash (override make_switch, add to ARGV) 
  optparse-string   string only API            #make_switch_from_string (override make_switch, add to ARGV)
  optparse-usage    git-like usage             #usage, #use (override to_s, use banner, use version, auto-add --help and --version, add to ARGV)
  optbind           bindings to vars           #bind, #bind! (bind to local/instance vars, support defaults, add to ARGV)
  opt ???           enhances syntax            see syntax def below
  optargs           supoort for args            

bind API:
  must be uninvasive, i.e. must not affect #on in any way, must act as #parse, see example
  ARGV, OptionParser (options)
  example: ARGV.options { |o| o.on(...); o.bind ...; o.parse! }
  on #bind call, #bind goes through all options (objects produced by make_switch) and binds them to variables 
  NO: ARGV.bind shortcut just ARGV.options.bind

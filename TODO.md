# TODOS

  - `Switch#parser_opts_from_string` - support regexps with options, like `=<name:/[a-z]/i>`
  - `Switch#parser_opts_from_string` - support ranges, like `=<indent:0..8>`
  - add default support for ranges on `OptionParser` level
  - add type conversion and patterns for arguments
  - make optional extensions for `OptionParser` monkey-patching `make_switch` to support hash-or-string-exclusive arguments 

# IDEAS

gems:
  optparse-struct   struct/hash-only API       #make_switch_from_struct, #make_switch_from_hash (override make_switch, add to ARGV) 
  optparse-string   string only API            #make_switch_from_string (override make_switch, add to ARGV)
  optparse-usage    git-like usage             #usage, #use (override to_s, use banner, use version, auto-add --help and --version, add to ARGV)
  optbind           bindings to vars           #bind, #bind! (bind to local/instance vars, support defaults, add to ARGV)
  opt ???           enhances syntax            see syntax def below
  optargs           supoort for args            

- store defaults and make them always accessible
- support arguments? consider ARGF

- bind API:
  must be uninvasive, i.e. must not affect #on in any way, must act as #parse, see example
  ARGV, OptionParser (options)
  bind
  to:, defaults: to,
    
  example: ARGV.options { |o| o.on(...); o.bind ...; o.parse! }
  on #bind call, #bind goes through all options (objects produced by make_switch) and binds them to variables 
  NO: ARGV.bind shortcut

- syntax def:

(ARGV|OptionParser.new).(def[ine]_and_bind[!]) to: (binding|hash|struct|object|self), [defaults: (to|*)], [locals: true] do [o]
  # locals: true must be explicitly set in case of to: (binding|object|self) otherwise instance vars are bound
  [o.](use|usage) ...
  [o.](use|usage) ...
  [o.](opt|option) ...
  [o.](opt|option) ...
  [o.](arg|argument) ... # after this line o#bind happens and optionally o#parse[!]
end[.parse[!]]

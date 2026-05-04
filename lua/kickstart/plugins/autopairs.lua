-- autopairs
-- https://github.com/windwp/nvim-autopairs

return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  opts = {},
  config = function(_, opts)
    local npairs = require 'nvim-autopairs'
    local Rule = require 'nvim-autopairs.rule'

    npairs.setup(opts)

    -- Zig struct declarations end with a semicolon: const Foo = struct { ... };
    npairs.add_rule(Rule('.*struct%s+{$', '};', 'zig'):use_regex(true, '{'))
    npairs.add_rule(Rule('.*return%s+%.%s*{$', '};', 'zig'):use_regex(true, '{'))
    npairs.add_rule(Rule('.*return%s+[%w_%.]+%s*{$', '};', 'zig'):use_regex(true, '{'))
  end,
}

-- autopairs
-- https://github.com/windwp/nvim-autopairs

return {
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  ft = 'zig',
  opts = {},
  config = function(_, opts)
    local npairs = require 'nvim-autopairs'
    local Rule = require 'nvim-autopairs.rule'

    npairs.setup(opts)

    -- Zig struct declarations end with a semicolon: const Foo = struct { ... };
    npairs.add_rule(Rule('.*struct%s+{$', '};', 'zig'):use_regex(true, '{'))
    npairs.add_rule(Rule('.*return%s+%.%s*{$', '};', 'zig'):use_regex(true, '{'))
    npairs.add_rule(Rule('.*return%s+[%w_%.]+%s*{$', '};', 'zig'):use_regex(true, '{'))

    local function install_zig_import_semicolon(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'zig' then
        return
      end

      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        vim.api.nvim_buf_set_keymap(bufnr, 'i', ')', '', {
          expr = true,
          noremap = true,
          desc = 'Zig import semicolon',
          callback = function()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before = line:sub(1, col)
            local next_char = line:sub(col + 1, col + 1)
            local char_after_next = line:sub(col + 2, col + 2)

            if next_char == ')' and char_after_next ~= ';' and before:match '@import%([^)]*$' then
              return vim.api.nvim_replace_termcodes('<Right>;', true, false, true)
            end

            return npairs.autopairs_map(bufnr, ')')
          end,
        })

        vim.api.nvim_buf_set_keymap(bufnr, 'i', '(', '', {
          expr = true,
          noremap = true,
          desc = 'Zig import semicolon',
          callback = function()
            local line = vim.api.nvim_get_current_line()
            local col = vim.api.nvim_win_get_cursor(0)[2]
            local before = line:sub(1, col)

            if before:match '@import$' then
              return vim.api.nvim_replace_termcodes('();<Left><Left>', true, false, true)
            end

            return npairs.autopairs_map(bufnr, '(')
          end,
        })
      end)
    end

    install_zig_import_semicolon(vim.api.nvim_get_current_buf())

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('kickstart-zig-autopairs', { clear = true }),
      callback = function(event)
        install_zig_import_semicolon(event.buf)
      end,
    })
  end,
}

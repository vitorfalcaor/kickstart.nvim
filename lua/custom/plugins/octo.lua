return {
  'pwntester/octo.nvim',
  cmd = 'Octo',
  opts = {
    picker = 'telescope',
    enable_builtin = true,
    mappings = {
      review_diff = {
        select_next_entry = { lhs = ']f', desc = 'move to next changed file' },
        select_prev_entry = { lhs = '[f', desc = 'move to previous changed file' },
      },
      file_panel = {
        select_next_entry = { lhs = ']f', desc = 'move to next changed file' },
        select_prev_entry = { lhs = '[f', desc = 'move to previous changed file' },
      },
      review_thread = {
        select_next_entry = { lhs = ']f', desc = 'move to next changed file' },
        select_prev_entry = { lhs = '[f', desc = 'move to previous changed file' },
      },
    },
  },
  keys = {
    { '<leader>oo', '<cmd>Octo<cr>', desc = 'Octo: Actions' },
    { '<leader>vb', '<cmd>Octo review browse<cr>', desc = 'Octo: Browse review' },
    { '<leader>oi', '<cmd>Octo issue list<cr>', desc = 'Octo: List issues' },
    { '<leader>op', '<cmd>Octo pr list<cr>', desc = 'Octo: List pull requests' },
    { '<leader>on', '<cmd>Octo notification list<cr>', desc = 'Octo: List notifications' },
    {
      '<leader>os',
      function()
        require('octo.utils').create_base_search_command { include_current_repo = true }
      end,
      desc = 'Octo: Search GitHub',
    },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  config = function(_, opts)
    require('octo').setup(opts)

    local function patch_octo_null_buffer_swapfile()
      local file_entry = require 'octo.reviews.file-entry'

      if file_entry._custom_null_buffer_swapfile_patch then
        return
      end

      file_entry._custom_null_buffer_swapfile_patch = true

      file_entry._get_null_buffer = function()
        local msg = 'Loading ...'
        local bufnr = file_entry._null_buffer[msg]

        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          return bufnr
        end

        local new_bufnr = vim.api.nvim_create_buf(false, true)
        vim.bo[new_bufnr].modifiable = true
        vim.api.nvim_buf_set_lines(new_bufnr, 0, -1, false, { msg })

        local bufname = require('octo.utils').path_join { 'octo', 'null' }
        vim.bo[new_bufnr].modified = false
        vim.bo[new_bufnr].modifiable = false
        vim.bo[new_bufnr].swapfile = false

        local ok = pcall(vim.api.nvim_buf_set_name, new_bufnr, bufname)
        if not ok then
          require('octo.utils').wipe_named_buffer(bufname)
          vim.api.nvim_buf_set_name(new_bufnr, bufname)
        end

        file_entry._null_buffer[msg] = new_bufnr

        return new_bufnr
      end
    end

    patch_octo_null_buffer_swapfile()

    local group = vim.api.nvim_create_augroup('CustomOctoReviewDiffMaps', { clear = true })
    local wrap_filetypes = {
      octo = true,
      octo_panel = true,
    }
    local function set_octo_review_diff_highlights()
      local ok, constants = pcall(require, 'octo.constants')
      if not ok then
        return
      end

      local function diff_bg(name, fallback)
        local ok_hl, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
        return ok_hl and hl.bg or fallback
      end

      -- Keep the diff background while letting syntax highlights provide the foreground.
      local add_bg = diff_bg('DiffAdd', 0x0f2f1c)
      local delete_bg = diff_bg('DiffDelete', 0x3a1618)

      for _, group_name in ipairs { 'DiffAdd', 'DiffChange', 'DiffText' } do
        vim.api.nvim_set_hl(constants.OCTO_REVIEW_RIGHT_HIGHLIGHT_NS, group_name, { bg = add_bg })
      end

      for _, group_name in ipairs { 'DiffDelete', 'DiffChange', 'DiffText' } do
        vim.api.nvim_set_hl(constants.OCTO_REVIEW_LEFT_HIGHLIGHT_NS, group_name, { bg = delete_bg })
      end
    end

    local function has_octo_diff_props(bufnr)
      return pcall(vim.api.nvim_buf_get_var, bufnr, 'octo_diff_props')
    end

    local function is_octo_review_file(bufnr)
      return vim.api.nvim_buf_get_name(bufnr):match '^octo://.-/review/.-/file/' ~= nil
    end

    local function set_octo_wrap_options(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.api.nvim_get_current_buf() ~= bufnr then
        return
      end

      if not wrap_filetypes[vim.bo[bufnr].filetype] and not has_octo_diff_props(bufnr) and not is_octo_review_file(bufnr) then
        return
      end

      vim.wo.wrap = true
      vim.wo.linebreak = true
      vim.wo.breakindent = true
    end

    local function diff_motion(keys)
      return function()
        vim.cmd('normal! ' .. vim.v.count1 .. keys)
      end
    end

    local function jump_to_first_hunk()
      local bufnr = vim.api.nvim_get_current_buf()
      if not has_octo_diff_props(bufnr) then
        return
      end

      pcall(vim.api.nvim_win_set_cursor, 0, { 1, 0 })

      if vim.fn.diff_hlID(1, 1) == 0 then
        pcall(vim.cmd, 'normal! ]c')
      end
    end

    local function select_file(direction)
      return function()
        local layout = require('octo.reviews').get_current_layout()
        if not layout then
          return
        end

        for _ = 1, vim.v.count1 do
          if direction == 'next' then
            layout:select_next_file()
          else
            layout:select_prev_file()
          end
        end

        vim.schedule(jump_to_first_hunk)
      end
    end

    local function set_review_diff_maps(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      local has_diff_props = has_octo_diff_props(bufnr)
      local is_file_panel = vim.bo[bufnr].filetype == 'octo_panel'

      if not has_diff_props and not is_file_panel then
        return
      end

      vim.keymap.set('n', ']f', select_file 'next', { buffer = bufnr, silent = true, desc = 'Octo: Next file' })
      vim.keymap.set('n', '[f', select_file 'prev', { buffer = bufnr, silent = true, desc = 'Octo: Previous file' })

      if has_diff_props then
        vim.keymap.set('n', ']c', diff_motion ']c', { buffer = bufnr, silent = true, desc = 'Octo: Next hunk' })
        vim.keymap.set('n', '[c', diff_motion '[c', { buffer = bufnr, silent = true, desc = 'Octo: Previous hunk' })
      end
    end

    vim.api.nvim_create_autocmd({ 'FileType', 'BufEnter', 'WinEnter' }, {
      group = group,
      callback = function(args)
        local bufnr = args.buf or vim.api.nvim_get_current_buf()

        set_octo_review_diff_highlights()
        set_octo_wrap_options(bufnr)
        set_review_diff_maps(bufnr)
      end,
    })

    vim.api.nvim_create_autocmd('ColorScheme', {
      group = group,
      callback = set_octo_review_diff_highlights,
    })
  end,
}

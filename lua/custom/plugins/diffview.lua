return {
  'sindrets/diffview.nvim',
  event = 'VeryLazy',
  config = function()
    local actions = require 'diffview.actions'
    require('diffview').setup {
      keymaps = {
        view = { ['q'] = actions.close },
        file_panel = { ['q'] = actions.close },
      },
    }
  end,
}

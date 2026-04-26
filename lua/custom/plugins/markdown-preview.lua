return {
  'selimacerbas/markdown-preview.nvim',
  ft = { 'markdown' },
  cmd = { 'MarkdownPreview', 'MarkdownPreviewRefresh', 'MarkdownPreviewStop' },
  dependencies = { 'selimacerbas/live-server.nvim' },
  config = function()
    require('markdown_preview').setup {
      open_browser = true,
      debounce_ms = 300,
    }
  end,
  keys = {
    { '<leader>mps', '<cmd>MarkdownPreview<cr>', desc = 'Markdown: Start preview' },
    { '<leader>mpS', '<cmd>MarkdownPreviewStop<cr>', desc = 'Markdown: Stop preview' },
    { '<leader>mpr', '<cmd>MarkdownPreviewRefresh<cr>', desc = 'Markdown: Refresh preview' },
  },
}

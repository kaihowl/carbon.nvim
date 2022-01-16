local util = require('carbon.util')
local buffer = require('carbon.buffer')
local watcher = require('carbon.watcher')
local settings = require('carbon.settings')
local carbon = {}

function carbon.setup(user_settings)
  if type(user_settings) == 'function' then
    user_settings(settings)
  else
    local next = vim.tbl_deep_extend('force', settings, user_settings)

    for setting, value in pairs(next) do
      settings[setting] = value
    end
  end

  return settings
end

function carbon.initialize()
  watcher.on('*', buffer.watch)

  util.command('Carbon', carbon.explore)
  util.command('Lcarbon', carbon.explore_left)

  util.map(util.plug('up'), carbon.up)
  util.map(util.plug('down'), carbon.down)
  util.map(util.plug('edit'), carbon.edit)
  util.map(util.plug('reset'), carbon.reset)
  util.map(util.plug('split'), carbon.split)
  util.map(util.plug('vsplit'), carbon.vsplit)

  vim.cmd([[
    augroup CarbonBufEnter
      autocmd! BufEnter carbon
          \ setlocal nowrap& nowrap |
          \ setlocal fillchars& fillchars=eob:\ |
          \ autocmd BufHidden <buffer>
              \ setlocal nowrap& fillchars& |
              \ let w:carbon_lexplore_window = v:false
    augroup END
  ]])

  if settings.sync_on_cd then
    vim.cmd([[
      augroup CarbonDirChanged
        autocmd! DirChanged global lua require("carbon").cd()
      augroup END
    ]])
  end

  if type(settings.highlights) == 'table' then
    for group, properties in pairs(settings.highlights) do
      util.highlight(group, properties)
    end
  end

  if not settings.keep_netrw then
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    util.command('Explore', 'Carbon')
    util.command('Lexplore', 'Lcarbon')
  end

  if settings.auto_open and vim.fn.isdirectory(vim.fn.expand('%:p')) == 1 then
    local current_buffer = vim.api.nvim_win_get_buf(0)

    buffer.show()
    vim.api.nvim_buf_delete(current_buffer, { force = true })
  end

  return carbon
end

function carbon.edit()
  local entry = buffer.cursor().entry

  if entry.is_directory then
    entry.is_open = not entry.is_open

    buffer.render()
  elseif vim.w.carbon_lexplore_window then
    vim.cmd('wincmd l')

    if vim.w.carbon_lexplore_window == vim.api.nvim_get_current_win() then
      vim.cmd('vertical belowright split ' .. entry.path)
      vim.cmd('wincmd p')
      vim.cmd('vertical resize ' .. tostring(settings.sidebar_width))
      vim.cmd('wincmd p')
    else
      vim.cmd('edit ' .. entry.path)
    end
  else
    vim.cmd('edit ' .. entry.path)
  end
end

function carbon.split()
  local entry = buffer.cursor().entry

  if not entry.is_directory then
    vim.cmd('split ' .. entry.path)
  end
end

function carbon.vsplit()
  local entry = buffer.cursor().entry

  if not entry.is_directory then
    vim.cmd('vsplit ' .. entry.path)
  end
end

function carbon.explore()
  buffer.show()
end

function carbon.explore_left()
  vim.cmd('vertical leftabove split')
  vim.cmd('vertical resize ' .. tostring(settings.sidebar_width))
  buffer.show()

  vim.w.carbon_lexplore_window = vim.api.nvim_get_current_win()
end

function carbon.up()
  if buffer.up() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function carbon.reset()
  if buffer.reset() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function carbon.down()
  if buffer.down() then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

function carbon.cd(path)
  if buffer.cd(path or vim.v.event.cwd) then
    vim.fn.cursor(1, 1)
    buffer.render()
  end
end

return carbon

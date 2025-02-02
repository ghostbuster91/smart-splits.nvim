local utils = require('smart-splits.utils')

local dir_keys_kitty = {
  left = 'left',
  right = 'right',
  up = 'top',
  down = 'bottom',
}

local function kitty_exec(args)
  local arguments = vim.deepcopy(args)
  table.insert(arguments, 1, 'kitty')
  table.insert(arguments, 2, '@')
  local password = vim.g.smart_splits_kitty_password or require('smart-splits.config').kitty_password or ''
  if #password > 0 then
    table.insert(arguments, 3, '--password')
    table.insert(arguments, 4, password)
  end
  return vim.fn.system(arguments)
end

---@type Multiplexer
local M = {}

function M.current_pane_id()
  local output = kitty_exec({ 'ls' })
  local kitty_info = vim.json.decode(output)
  if #kitty_info == 0 then
    return nil
  end

  local active_client = utils.tbl_find(kitty_info, function(client)
    -- if we're doing a keymap, obviously the terminal must be focused also
    return client.is_active and client.is_focused
  end)

  if not active_client then
    return nil
  end

  local active_tab = utils.tbl_find(active_client.tabs, function(tab)
    -- different versions of Kitty have different output for this
    return (tab.is_active or tab.is_active_tab) and tab.is_focused
  end)

  if not active_tab then
    return nil
  end

  local active_pane = utils.tbl_find(active_tab.windows, function(window)
    -- different versions of Kitty have different output for this
    return (window.is_active or window.is_active_window) and window.is_focused
  end)

  if not active_pane then
    return nil
  end

  return active_pane.id
end

function M.current_pane_at_edge()
  return false
end

function M.is_in_session()
  -- Kitty requires that remote control is enabled to send commands to it
  return vim.env.KITTY_LISTEN_ON ~= nil and #vim.env.KITTY_LISTEN_ON > 0
end

function M.current_pane_is_zoomed()
  return false
end

function M.next_pane(direction)
  if not M.is_in_session() then
    return false
  end

  direction = dir_keys_kitty[direction] ---@diagnostic disable-line
  local ok, _ = pcall(function()
    kitty_exec({ 'kitten', 'neighboring_window.py', direction })
  end)

  return ok
end

function M.resize_pane(_, _)
  if not M.is_in_session() then
    return false
  end

  -- not possible with Kitty, since Kitty uses wider/narrower/taller/shorter
  -- instead of up/down/left/right
  return false
end

return M

<div align="center">

# 🧠 `smart-splits.nvim`

</div>

🧠 Smarter and more intuitive split pane management that uses a mental model of left/right/up/down
instead of wider/narrower/taller/shorter for resizing. Supports seamless navigation between Neovim and terminal
multiplexer split panes. See [Multiplexer Integrations](#multiplexer-integrations).

![demo](https://user-images.githubusercontent.com/8648891/201928611-4338e3cb-cca9-4e15-92c6-0405b7072279.gif)

<details>
<summary>Table of Contents (click to expand)</summary>

- [Install](#install)
- [Configuration](#configuration)
  - [Hooks](#hooks)
    - [Examples:](#examples)
- [Usage](#usage)
  - [Multiplexer Integrations](#multiplexer-integrations)
    - [Tmux](#tmux)
    - [Wezterm](#wezterm)
    - [Kitty](#kitty)
      - [Credits](#credits)

</details>

## Install

`smart-splits.nvim` now supports semantic versioning via git tags. See [Releases](https://github.com/mrjones2014/smart-splits.nvim/releases)
for a full list of versions and their changelogs, starting from 1.0.0.

With Packer.nvim:

```lua
use('mrjones2014/smart-splits.nvim')
-- or use a specific version
use({ 'mrjones2014/smart-splits.nvim', tag = 'v1.0.0' })
-- to use Kitty multiplexer support, run the post install hook
use({ 'mrjones2014/smart-splits.nvim', run = './kitty/install-kittens.bash' })
```

With Lazy.nvim:

```lua
{ 'mrjones2014/smart-splits.nvim' }
-- or use a specific version, or a range of versions using lazy.nvim's version API
{ 'mrjones2014/smart-splits.nvim', version = '>=1.0.0' }
-- to use Kitty multiplexer support, run the post install hook
{ 'mrjones2014/smart-splits.nvim', build = './kitty/install-kittens.bash' }
```

## Configuration

You can set ignored `buftype`s or `filetype`s which will be ignored when
figuring out if your cursor is currently at an edge split for resizing.
This is useful in order to ignore "sidebar" type buffers while resizing,
such as [nvim-tree.lua](https://github.com/kyazdani42/nvim-tree.lua)
which tries to maintain its own width unless manually resized. Note that
nothing is ignored when moving between splits, only when resizing.

Defaults are shown below:

```lua
require('smart-splits').setup({
  -- Ignored filetypes (only while resizing)
  ignored_filetypes = {
    'nofile',
    'quickfix',
    'prompt',
  },
  -- Ignored buffer types (only while resizing)
  ignored_buftypes = { 'NvimTree' },
  -- the default number of lines/columns to resize by at a time
  default_amount = 3,
  -- whether to wrap to opposite side when cursor is at an edge
  -- e.g. by default, moving left at the left edge will jump
  -- to the rightmost window, and vice versa, same for up/down.
  wrap_at_edge = true,
  -- when moving cursor between splits left or right,
  -- place the cursor on the same row of the *screen*
  -- regardless of line numbers. False by default.
  -- Can be overridden via function parameter, see Usage.
  move_cursor_same_row = false,
  -- whether the cursor should follow the buffer when swapping
  -- buffers by default; it can also be controlled by passing
  -- `{ move_cursor = true }` or `{ move_cursor = false }`
  -- when calling the Lua function.
  cursor_follows_swapped_bufs = false,
  -- resize mode options
  resize_mode = {
    -- key to exit persistent resize mode
    quit_key = '<ESC>',
    -- keys to use for moving in resize mode
    -- in order of left, down, up' right
    resize_keys = { 'h', 'j', 'k', 'l' },
    -- set to true to silence the notifications
    -- when entering/exiting persistent resize mode
    silent = false,
    -- must be functions, they will be executed when
    -- entering or exiting the resize mode
    hooks = {
      on_enter = nil,
      on_leave = nil,
    },
  },
  -- ignore these autocmd events (via :h eventignore) while processing
  -- smart-splits.nvim computations, which involve visiting different
  -- buffers and windows. These events will be ignored during processing,
  -- and un-ignored on completed. This only applies to resize events,
  -- not cursor movement events.
  ignored_events = {
    'BufEnter',
    'WinEnter',
  },
  -- enable or disable a multiplexer integration;
  -- automatically determined, unless explicitly disabled or set,
  -- by checking the $TERM_PROGRAM environment variable,
  -- and the $KITTY_LISTEN_ON environment variable for Kitty
  multiplexer_integration = nil,
  -- disable multiplexer navigation if current multiplexer pane is zoomed
  -- this functionality is only supported on tmux and Wezterm due to kitty
  -- not having a way to check if a pane is zoomed
  disable_multiplexer_nav_when_zoomed = true,
})
```

### Hooks

The hook table allows you to define callbacks for the `on_enter` and `on_leave` events of the resize mode.

##### Examples:

Integration with [bufresize.nvim](https://github.com/kwkarlwang/bufresize.nvim):

```lua
require('smart-splits').setup({
  resize_mode = {
    hooks = {
      on_leave = require('bufresize').register,
    },
  },
})
```

Custom messages when using resize mode:

```lua
require('smart-splits').setup({
  resize_mode = {
    silent = true,
    hooks = {
      on_enter = function()
        vim.notify('Entering resize mode')
      end,
      on_leave = function()
        vim.notify('Exiting resize mode, bye')
      end,
    },
  },
})
```

## Usage

With Lua:

```lua
-- resizing splits
-- amount defaults to 3 if not specified
-- use absolute values, no + or -
-- the functions also check for a range,
-- so for example if you bind `<A-h>` to `resize_left`,
-- then `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
require('smart-splits').resize_up(amount)
require('smart-splits').resize_down(amount)
require('smart-splits').resize_left(amount)
require('smart-splits').resize_right(amount)
-- moving between splits
-- pass same_row as a boolean to override the default
-- for the move_cursor_same_row config option.
-- See Configuration.
require('smart-splits').move_cursor_up()
require('smart-splits').move_cursor_down()
require('smart-splits').move_cursor_left(same_row)
require('smart-splits').move_cursor_right(same_row)
-- Swapping buffers directionally with the window to the specified direction
require('smart-splits').swap_buf_up()
require('smart-splits').swap_buf_down()
require('smart-splits').swap_buf_left()
require('smart-splits').swap_buf_right()
-- the buffer swap functions can also take an `opts` table to override the
-- default behavior of whether or not the cursor follows the buffer
require('smart-splits').swap_buf_right({ move_cursor = true })
-- persistent resize mode
-- temporarily remap your configured resize keys to
-- smart resize left, down, up, and right, respectively,
-- press <ESC> to stop resize mode (unless you've set a different key in config)
-- resize keys also accept a range, e.e. pressing `5j` will resize down 5 times the default_amount
require('smart-splits').start_resize_mode()

-- recommended mappings
-- resizing splits
-- these keymaps will also accept a range,
-- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
-- moving between splits
vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)
-- swapping buffers between windows
vim.keymap.set('n', '<leader><leader>h', require('smart-splits').swap_buf_left)
vim.keymap.set('n', '<leader><leader>j', require('smart-splits').swap_buf_down)
vim.keymap.set('n', '<leader><leader>k', require('smart-splits').swap_buf_up)
vim.keymap.set('n', '<leader><leader>l', require('smart-splits').swap_buf_right)
```

### Multiplexer Integrations

`smart-splits.nvim` can also enable seamless navigation between Neovim splits and `tmux`, `wezterm`, or `kitty`\* panes.
You will need to set up keymaps in your `tmux`, `wezterm`, or `kitty` configs to match the Neovim keymaps.

\* Directional resizing not supported in Kitty due to lack of CLI support to do so.

#### Tmux

Add the following snippet to your `~/.tmux.conf`/`~/.config/tmux/tmux.conf` file (customizing the keys and resize amount if desired):

```tmux
# Smart pane switching with awareness of Vim splits.
# See: https://github.com/christoomey/vim-tmux-navigator
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
bind-key -n C-h if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
bind-key -n C-j if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
bind-key -n C-k if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
bind-key -n C-l if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

bind-key -n M-h if-shell "$is_vim" 'send-keys M-h' 'resize-pane -L 3'
bind-key -n M-j if-shell "$is_vim" 'send-keys M-j' 'resize-pane -D 3'
bind-key -n M-k if-shell "$is_vim" 'send-keys M-k' 'resize-pane -U 3'
bind-key -n M-l if-shell "$is_vim" 'send-keys M-l' 'resize-pane -R 3'

tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
    "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
bind-key -T copy-mode-vi 'C-\' select-pane -l
```

#### Wezterm

> **Note**
> If you are experiencing performance issues with circular navigation, they are solved by [wez/wezterm@96f1585](https://github.com/wez/wezterm/commit/96f1585b103162b042e2593567884dfcbe32ca21),
> so try using Wezterm nightly for now.

Add the following snippet to your `~/.config/wezterm/wezterm.lua`:

```lua
local w = require('wezterm')

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

local function is_vim(pane)
  local process_name = basename(pane:get_foreground_process_name())
  return process_name == 'nvim' or process_name == 'vim'
end

local direction_keys = {
  Left = 'h',
  Down = 'j',
  Up = 'k',
  Right = 'l',
  -- reverse lookup
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META' or 'CTRL',
    action = w.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == 'resize' and 'META' or 'CTRL' },
        }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

return {
  keys = {
    -- move between split panes
    split_nav('move', 'h'),
    split_nav('move', 'j'),
    split_nav('move', 'k'),
    split_nav('move', 'l'),
    -- resize panes
    split_nav('resize', 'h'),
    split_nav('resize', 'j'),
    split_nav('resize', 'k'),
    split_nav('resize', 'l'),
  },
}
```

#### Kitty

Add the following snippet to `~/.config/kitty/kitty.conf`, adjusting the keymaps as desired.

```
map ctrl+j kitten pass_keys.py neighboring_window bottom ctrl+j
map ctrl+k kitten pass_keys.py neighboring_window top    ctrl+k
map ctrl+h kitten pass_keys.py neighboring_window left   ctrl+h
map ctrl+l kitten pass_keys.py neighboring_window right  ctrl+l
```

By default, it matches against the name of the current foreground process to detect if `vim`/`nvim` is running.
If that doesn't work for you, or you want to include other CLI/TUI programs in the exclusion, you can provide
an additional regex argument:

```
map ctrl+j kitten pass_keys.py neighboring_window bottom ctrl+j "^.* - nvim$"
map ctrl+k kitten pass_keys.py neighboring_window top    ctrl+k "^.* - nvim$"
map ctrl+h kitten pass_keys.py neighboring_window left   ctrl+h "^.* - nvim$"
map ctrl+l kitten pass_keys.py neighboring_window right  ctrl+l "^.* - nvim$"
```

Then, you must allow Kitty to listen for remote commands on a socket. You can do this
either by running Kitty with the following command:

```bash
# For linux only:
kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty

# Other unix systems:
kitty -o allow_remote_control=yes --single-instance --listen-on unix:/tmp/mykitty
```

Or, by adding the following to `~/.config/kitty/kitty.conf`:

```
# For linux only:
allow_remote_control yes
listen_on unix:@mykitty

# Other unix systems:
allow_remote_control yes
listen_on unix:/tmp/mykitty
```

##### Credits

Thanks @knubie for inspiration for the Kitty implementation from [vim-kitty-navigator](https://github.com/knubie/vim-kitty-navigator).

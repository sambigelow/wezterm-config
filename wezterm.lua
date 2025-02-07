-- Pull in the wezterm API
local wezterm = require 'wezterm'
local action = wezterm.action
local mux = wezterm.mux

local config = wezterm.config_builder()
wezterm.plugin.list()

wezterm.on('gui-startup', function(cmd)
  local args = {}
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
  if cmd then
    args = cmd.args
  end

  local project_dir = wezterm.home_dir .. '/workspace/recipes'
  local tab, build_pane, window = mux.spawn_window {
    workspace = 'coding',
    cwd = project_dir,
    args = args,
  }
  local editor_pane = build_pane:split {
    direction = 'Top',
    size = 0.6,
    cwd = project_dir,
  }
  -- may as well kick off a build in that pane
  build_pane:send_text 'cargo build\n'

  -- A workspace for interacting with a local machine that
  -- runs some docker containers for home automation
  local tab, pane, window = mux.spawn_window {
    workspace = 'automation',
    args = { 'ssh', 'vault' },
  }

  -- We want to startup in the coding workspace
  mux.set_active_workspace 'coding'
end)

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
    mods = resize_or_move == 'resize' and 'META' or 'CMD',
    action = wezterm.action_callback(function(win, pane)
      if resize_or_move == 'resize' then
        win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
      else
        win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
      end
    end),
  }
end

config.color_scheme = 'Catppuccin Macchiato'
config.use_fancy_tab_bar = false
config.font = wezterm.font '0xProto Nerd Font Mono'
config.font_size = 14
config.window_decorations = 'RESIZE'
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1500 }
config.keys = {
  {
    mods = 'CMD',
    key = '|',
    action = action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    mods = 'CMD',
    key = '_',
    action = action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    mods = 'CMD',
    key = 'w',
    action = action.CloseCurrentPane { confirm = false },
  },
  {
    mods = 'LEADER',
    key = 'n',
    action = action.ActivateTabRelative(1),
  },
  {
    mods = 'LEADER',
    key = 'p',
    action = action.ActivateTabRelative(-1),
  },
  {
    mods = 'LEADER',
    key = 'm',
    action = wezterm.action.TogglePaneZoomState,
  },
  {
    mods = 'LEADER',
    key = 'Space',
    action = wezterm.action.RotatePanes 'Clockwise',
  },
  {
    mods = 'LEADER',
    key = 'Enter',
    action = wezterm.action.PaneSelect {
      mode = 'SwapWithActive',
    },
  },
  {
    mods = 'LEADER',
    key = '[',
    action = wezterm.action.ActivateCopyMode,
  },
  { key = 'l', mods = 'ALT', action = wezterm.action.ShowLauncher },
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
}

-- and finally, return the configuration to wezterm
return config

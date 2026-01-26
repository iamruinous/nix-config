{pkgs, ...}: let
  window_decorations =
    if pkgs.stdenv.isDarwin
    then "RESIZE"
    else "NONE";
  # 1Password SSH agent socket path
  onePasswordAgentSock =
    if pkgs.stdenv.isDarwin
    then "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else "~/.1password/agent.sock";
in {
  # Install wezterm via home-manager module
  programs.wezterm = {
    extraConfig = ''
      -- Creates a config object which we will be adding our config to
      local config = wezterm.config_builder()
      -- config.set_environment_variables = {
      --   PATH = '/run/current-system/sw/bin:' .. os.getenv('PATH')
      -- }

      -- Use 1Password SSH agent instead of system default
      local onep_auth = wezterm.home_dir .. '/${
        if pkgs.stdenv.isDarwin
        then "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        else ".1password/agent.sock"
      }'
      if #wezterm.glob(onep_auth) == 1 then
        config.default_ssh_auth_sock = onep_auth
      end

      -- (This is where our config will go)
      -- Pick a colour scheme. WezTerm ships with more than 1,000!
      -- Find them here: https://wezfurlong.org/wezterm/colorschemes/index.html
      config.color_scheme = 'Tokyo Night'

      -- Choose your favourite font, make sure it's installed on your machine
      config.font = wezterm.font({ family = 'FiraCode Nerd Font Mono' })
      -- And a font size that won't have you squinting
      config.font_size = 18

      -- Solid background for proper tmux-powerkit separator rendering
      -- (0.9 opacity causes visual artifacts with powerline separators)
      config.window_background_opacity = 1.0
      config.macos_window_background_blur = 30
      -- Removes the title bar, leaving only the tab bar. Keeps
      -- the ability to resize by dragging the window's edges.
      -- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
      -- you want to keep the window controls visible and integrate
      -- them into the tab bar.
      config.window_decorations = '${window_decorations}'
      -- Sets the font for the window frame (tab bar)
      config.window_frame = {
        -- Berkeley Mono for me again, though an idea could be to try a
        -- serif font here instead of monospace for a nicer look?
        font = wezterm.font({ family = 'MonaspiceNe Nerd Font' }),
        font_size = 13,
      }

      -- Show notifications if not currently focused
      config.notification_handling = 'AlwaysShow'

      local function segments_for_right_status(window)
        return {
          -- window:active_workspace(),
          wezterm.strftime('%a %b %-d < %H:%M'),
          wezterm.hostname(),
        }
      end

      wezterm.on('update-status', function(window, _)
        -- local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
        local SOLID_LEFT_SEGMENT = utf8.char(0xe0b6)
        local segments = segments_for_right_status(window)

        local color_scheme = window:effective_config().resolved_palette
        -- Note the use of wezterm.color.parse here, this returns
        -- a Color object, which comes with functionality for lightening
        -- or darkening the colour (amongst other things).
        local bg = wezterm.color.parse(color_scheme.background)
        local fg = color_scheme.foreground

        -- Each powerline segment is going to be coloured progressively
        -- darker/lighter depending on whether we're on a dark/light colour
        -- scheme. Let's establish the "from" and "to" bounds of our gradient.
        local gradient_to, gradient_from = bg
        gradient_from = gradient_to:lighten(0.2)

        -- Yes, WezTerm supports creating gradients, because why not?! Although
        -- they'd usually be used for setting high fidelity gradients on your terminal's
        -- background, we'll use them here to give us a sample of the powerline segment
        -- colours we need.
        local gradient = wezterm.color.gradient(
          {
            orientation = 'Horizontal',
            colors = { gradient_from, gradient_to },
          },
          #segments -- only gives us as many colours as we have segments.
        )

        -- We'll build up the elements to send to wezterm.format in this table.
        local elements = {}

        for i, seg in ipairs(segments) do
          local is_first = i == 1

          if is_first then
            table.insert(elements, { Background = { Color = 'none' } })
          end
          table.insert(elements, { Foreground = { Color = gradient[i] } })
          table.insert(elements, { Text = SOLID_LEFT_SEGMENT })

          table.insert(elements, { Foreground = { Color = fg } })
          table.insert(elements, { Background = { Color = gradient[i] } })
          table.insert(elements, { Text = ' ' .. seg .. ' ' })
        end

        window:set_right_status(wezterm.format(elements))
      end)

      -- Table mapping keypresses to actions
      config.keys = {
        -- Sends a newline for multiline editing
        -- in AI tools like Claude Code
        {
          key = 'Enter',
          mods = 'SHIFT',
          action = wezterm.action.SendString '\x1b\r',
        },
        -- Sends ESC + b and ESC + f sequence, which is used
        -- for telling your shell to jump back/forward.
        {
          -- When the left arrow is pressed
          key = 'LeftArrow',
          -- With the "Option" key modifier held down
          mods = 'OPT',
          -- Perform this action, in this case - sending ESC + B
          -- to the terminal
          action = wezterm.action.SendString '\x1bb',
        },
        {
          key = 'RightArrow',
          mods = 'OPT',
          action = wezterm.action.SendString '\x1bf',
        },
        {
          key = ',',
          mods = 'SUPER',
          action = wezterm.action.SpawnCommandInNewTab {
            cwd = wezterm.home_dir,
            args = { 'nvim', wezterm.config_file },
          },
        },
        -- CTRL-SHIFT-l activates the debug overlay
        { key = 'L', mods = 'CTRL', action = wezterm.action.ShowDebugOverlay },
      }

      -- Returns our config to be evaluated. We must always do this at the bottom of this file
      return config
    '';
  };
}

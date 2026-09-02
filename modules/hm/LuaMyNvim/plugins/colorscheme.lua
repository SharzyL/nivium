return function(vim)
  -- onedark in both styles: nvim's own default scheme would do the light side,
  -- but its page is #e0e2ea, a blue-grey rather than the terminal's white, and
  -- 57 groups across barbar, telescope, notify and neo-tree hardcode it, so
  -- there is no cheap way to let the terminal show through. onedark's light
  -- palette is #fafafa. 'background' itself is decided in ../parts/opt.lua.

  -- Two plugins need help whichever scheme is loaded: barbar's buffer labels
  -- (unreadable under the default scheme) and neo-tree's source selector, whose
  -- tab groups no colorscheme defines -- neo-tree then derives them by fading
  -- towards black, giving a near-black strip on any background. Both are
  -- expressed against the active scheme, so there is one list, not one per
  -- scheme.
  -- mix two 24-bit colors; t = 0 keeps a, t = 1 gives b
  local function blend(a, b, t)
    local out = 0
    for _, shift in ipairs({ 16, 8, 0 }) do
      local ca = math.floor(a / 2 ^ shift) % 256
      local cb = math.floor(b / 2 ^ shift) % 256
      out = out + math.floor(ca + (cb - ca) * t + 0.5) * 2 ^ shift
    end
    return math.floor(out)
  end

  local function palette()
    local function of(group, key, fallback)
      local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
      return hl[key] or fallback
    end
    local fg, bg = of('Normal', 'fg'), of('Normal', 'bg')
    return {
      fg = fg,
      bg = bg,
      surface = of('Pmenu', 'bg', bg), -- one step off the editor background
      -- dimmed by mixing towards the background rather than taken from Comment,
      -- whose color onedark deliberately sinks to 2.3:1
      muted = blend(fg, bg, 0.35),
      accent = of('Function', 'fg', fg),
    }
  end

  local function set_plugin_highlights()
    local p = palette()
    local groups = {
      BufferCurrent = { fg = p.fg, bg = p.surface, bold = true },
      BufferCurrentSign = { fg = p.accent, bg = p.surface, bold = true },
      BufferInactive = { fg = p.muted, bg = p.bg },
      BufferInactiveSign = { bg = p.bg },
      BufferTabpageFill = { bg = p.bg },

      WinBar = { bg = p.surface },

      -- neo-tree's own derivations: it fades these towards black
      NeoTreeDimText = { fg = p.muted, bg = p.bg },
      NeoTreeMessage = { fg = p.muted, bg = p.bg },
      NeoTreeTitleBar = { fg = p.fg, bg = p.surface },
      NeoTreeTabActive = { fg = p.fg, bg = p.bg, bold = true },
      NeoTreeTabInactive = { fg = p.muted, bg = p.surface },
      NeoTreeTabSeparatorActive = { fg = p.surface, bg = p.bg },
      NeoTreeTabSeparatorInactive = { fg = p.surface, bg = p.surface },
    }
    for name, spec in pairs(groups) do
      vim.api.nvim_set_hl(0, name, spec)
    end
  end

  local function apply()
    -- The style has to be named on every load: onedark latches style = 'light'
    -- once it has seen a light background, and going back to dark would then
    -- keep the light palette.
    local style = (vim.o.background == 'light') and 'light' or 'dark'
    require('onedark').setup({
      style = style,
      -- bg_d is the panel background of the seven groups onedark draws behind
      -- neo-tree. It is a slight recess in the dark palette but #c9c9c9 against
      -- an #fafafa editor in the light one, a heavy grey slab. Corrected in the
      -- palette rather than afterwards, because onedark defines those groups
      -- itself and would overwrite anything set later.
      colors = { bg_d = require('onedark.palette')[style].bg0 },
    })
    require('onedark').load({})
  end

  -- registered before the first apply, so it also runs for that one, and again
  -- after every scheme change
  vim.api.nvim_create_autocmd('ColorScheme', {
    -- on the next tick, not inline: a 'background' change makes nvim re-source
    -- the colorscheme *after* this event, without firing it again, which would
    -- wipe these
    callback = function()
      vim.schedule(set_plugin_highlights)
    end,
    desc = 're-apply the plugin highlights the colorscheme does not cover',
  })

  -- neo-tree installs its own highlights when the panel first opens, after the
  -- reload above has already run, so the panel needs one more pass then
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'neo-tree',
    callback = function()
      vim.schedule(set_plugin_highlights)
    end,
    desc = 're-apply the highlights neo-tree overwrites when it opens',
  })

  apply()

  -- nvim reloads the *current* colorscheme when 'background' changes, so without
  -- this a session that starts dark and then learns the terminal is light would
  -- land back on onedark's light palette
  vim.api.nvim_create_autocmd('OptionSet', {
    pattern = 'background',
    callback = apply,
    desc = 'reload the colorscheme in the style that suits the background',
  })
end

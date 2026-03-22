package.path = './?.lua;' .. package.path

local geometry = {
  new = function(cell) return { raw = cell } end,
  type = function() return 'size' end,
  size = function(x, y) return { w = x, h = y } end,
}

setmetatable(geometry, {
  __call = function(_, value)
    return value
  end,
})

local captured = {}

hs = {
  spoons = {
    resourcePath = function(name)
      return './' .. name
    end,
  },
  screen = {
    mainScreen = function() return 'MAIN' end,
    find = function(ref)
      if ref == 'UUID-1' or ref == 'External Display' then
        return 'SCREEN<' .. tostring(ref) .. '>'
      end

      return nil
    end,
  },
  layout = {
    apply = function(elements)
      captured = elements
    end,
  },
  application = {
    open = function() return nil end,
    get = function() return nil end,
  },
  window = {
    visibleWindows = function() return {} end,
  },
  fnutils = {
    find = function() return nil end,
  },
  geometry = geometry,
  grid = {
    getGridFrame = function() return { x = 0, y = 0, w = 600, h = 200 } end,
    getGrid = function() return { w = 60, h = 20 } end,
    setMargins = function() end,
  },
}

package.loaded['hs.grid'] = hs.grid
package.loaded['hs.geometry'] = hs.geometry
package.loaded['hs.screen'] = hs.screen

local helpers = dofile('./helpers.lua')
helpers.grid.getCellWithMargins = function(cell, screen)
  return {
    cell = cell,
    screen = screen or 'MAIN',
  }
end

local function byAppId(elements, appId)
  for _, element in ipairs(elements or {}) do
    if element[1] == appId then
      return element
    end
  end

  return nil
end

local state = {
  current_layout_key = 1,
  current_layout_variant = 1,
  layouts = helpers.normalizeLayouts({
    {
      name = 'Compatibility',
      cells = {
        '0,0 30x20',
        { '30,0 30x20', '0,0 60x20' },
        { cell = '0,0 15x20', screen = 'UUID-1' },
        {
          { cell = '0,0 20x20', screen = 'External Display' },
          '20,0 40x20',
        },
      },
      apps = {
        Terminal = { cell = 1 },
        Browser = { cell = 2 },
        Slack = { cell = 3 },
        Obsidian = { cell = 4 },
      },
    },
  }),
  apps = {
    Terminal = { id = 'term' },
    Browser = { id = 'browser' },
    Slack = { id = 'slack' },
    Obsidian = { id = 'obsidian' },
  },
  layout_customizations = {},
}

helpers.applyLayout(1, 1, state)

assert(byAppId(captured, 'term')[5].cell == '0,0 30x20', 'legacy string cells should still normalize')
assert(byAppId(captured, 'term')[5].screen == 'MAIN', 'legacy string cells should still resolve to the main screen')

assert(byAppId(captured, 'browser')[5].cell == '30,0 30x20', 'legacy variant arrays should still normalize')
assert(byAppId(captured, 'browser')[5].screen == 'MAIN', 'legacy variant arrays should still resolve to the main screen')

assert(byAppId(captured, 'slack')[5].cell == '0,0 15x20', 'screen-aware cells should resolve nested cell values')
assert(byAppId(captured, 'slack')[5].screen == 'SCREEN<UUID-1>', 'screen-aware cells should resolve target screens')

assert(byAppId(captured, 'obsidian')[5].cell == '0,0 20x20', 'screen-aware variant arrays should resolve correctly')
assert(byAppId(captured, 'obsidian')[5].screen == 'SCREEN<External Display>', 'screen-aware variant arrays should resolve screen refs')

helpers.applyLayout(1, 2, state)

assert(byAppId(captured, 'obsidian')[5].cell == '20,0 40x20', 'mixed variant arrays should still allow plain string variants')
assert(byAppId(captured, 'obsidian')[5].screen == 'MAIN', 'plain string variants should still fall back to the main screen')

print('helpers_spec ok')

package.path = './?.lua;' .. package.path

local function parseCell(value)
  local x, y, w, h = value:match('^(%-?[%d%.]+),(%-?[%d%.]+)%s+([%d%.]+)x([%d%.]+)$')

  if not x then
    return nil
  end

  return {
    x = tonumber(x),
    y = tonumber(y),
    w = tonumber(w),
    h = tonumber(h),
  }
end

local function parseSize(value)
  local w, h = value:match('^([%d%.]+)x([%d%.]+)$')

  if not w then
    return nil
  end

  return {
    w = tonumber(w),
    h = tonumber(h),
  }
end

local geometry = {
  new = function(value)
    if type(value) ~= 'string' then
      return value
    end

    return parseCell(value) or parseSize(value)
  end,
  type = function(value)
    if type(value) ~= 'table' then
      return nil
    end

    if value.x ~= nil and value.y ~= nil and value.w ~= nil and value.h ~= nil then
      return 'rect'
    end

    if value.w ~= nil and value.h ~= nil then
      return 'size'
    end

    return nil
  end,
  size = function(x, y) return { w = x, h = y } end,
}

setmetatable(geometry, {
  __call = function(_, value)
    return geometry.new(value)
  end,
})

local function newScreen(name, uuid, frame)
  return {
    _name = name,
    _uuid = uuid,
    _frame = frame,
    name = function(self) return self._name end,
    getUUID = function(self) return self._uuid end,
  }
end

local screens = {
  main = newScreen('Main Display', 'UUID-MAIN', { x = 0, y = 0, w = 600, h = 200 }),
  external = newScreen('External Display', 'UUID-1', { x = 600, y = 0, w = 600, h = 200 }),
  builtIn = newScreen('Built-in Retina Display', 'UUID-BUILTIN', { x = 1200, y = 0, w = 600, h = 200 }),
}

local allScreens = { screens.main, screens.external, screens.builtIn }

local captured = {}

hs = {
  spoons = {
    resourcePath = function(name)
      return './' .. name
    end,
  },
  screen = {
    allScreens = function()
      return allScreens
    end,
    mainScreen = function()
      return screens.main
    end,
    find = function(ref)
      if ref == nil then
        return nil
      end

      if type(ref) == 'table' then
        for _, screen in ipairs(allScreens) do
          if screen == ref then
            return screen
          end
        end

        return nil
      end

      if type(ref) == 'string' then
        local needle = ref:lower()

        for _, screen in ipairs(allScreens) do
          if screen:getUUID() == ref then
            return screen
          end

          local name = screen:name()
          if name and name:lower():find(needle) then
            return screen
          end
        end
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
    getGridFrame = function(screen)
      return screen._frame
    end,
    getGrid = function() return { w = 60, h = 20 } end,
    setMargins = function() end,
  },
}

package.loaded['hs.grid'] = hs.grid
package.loaded['hs.geometry'] = hs.geometry
package.loaded['hs.screen'] = hs.screen

local helpers = dofile('./helpers.lua')

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
          { cell = '0,0 20x20', screen = 'Built-in Retina Display' },
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

local builtInFrame = helpers.grid.getCellWithMargins('0,0 20x20', 'Built-in Retina Display')
assert(builtInFrame.x == 1205, 'literal display names should resolve exact screens when computing frames')

helpers.applyLayout(1, 1, state)

assert(byAppId(captured, 'term')[5].x == 5, 'legacy string cells should still compute against the main screen')
assert(byAppId(captured, 'term')[3] == nil, 'legacy string cells should not force a display override')

assert(byAppId(captured, 'browser')[5].x == 302.5, 'legacy variant arrays should still normalize')
assert(byAppId(captured, 'browser')[3] == nil, 'legacy variant arrays should not force a display override')

assert(byAppId(captured, 'slack')[5].x == 605, 'screen-aware cells should compute against UUID-matched screens')
assert(byAppId(captured, 'slack')[3] == screens.external, 'screen-aware cells should pass the resolved display to hs.layout.apply')

assert(byAppId(captured, 'obsidian')[5].x == 1205, 'screen-aware variant arrays should honor literal display names with Lua pattern chars')
assert(byAppId(captured, 'obsidian')[3] == screens.builtIn, 'screen-aware variant arrays should pass exact-name displays through as screen objects')

helpers.applyLayout(1, 2, state)

assert(byAppId(captured, 'obsidian')[5].x == 202.5, 'mixed variant arrays should still allow plain string variants')
assert(byAppId(captured, 'obsidian')[3] == nil, 'plain string variants should not set an explicit display')

print('helpers_spec ok')

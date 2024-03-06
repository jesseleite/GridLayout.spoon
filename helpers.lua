local M = {}

-- Extra grid helper, which maybe we can PR to hammerspoon and/or remove later.
M.grid = dofile(hs.spoons.resourcePath('grid.lua'))

-- Normalize layout table from spoon convention for use in hs.layout.apply().
function M.normalizeLayoutForApply(layout, state)
  if not layout.apps then
    return layout
  end

  local normalized = {}

  for app,config in pairs(layout.apps) do
    table.insert(normalized, M.normalizeElementForApply(
      state.apps[app].id,
      state.apps[app].window,
      config.cell,
      layout,
      state
    ))
  end

  return normalized
end

-- Apply single layout element for use in hs.layout.apply.
function M.normalizeElementForApply(app_id, window, cell, layout, state)
  return {
    app_id,
    window,
    nil,
    nil,
    M.grid.getCellWithMargins(layout.cells[cell][state.current_layout_variant]),
  }
end

-- Ensure app is open if `open = true` in layout.apps configuration.
-- Also ensure app is unhidden.
function M.ensureOpenWhenConfigured(layoutApps, allApps)
  for name,config in pairs(layoutApps) do
    local app
    if config.open then
      app = hs.application.open(allApps[name].id or name, 10, true)
    else
      app = hs.application.get(allApps[name].id or name)
    end
    if app == nil then return end
    app:unhide()
  end
end

-- Hide all windows except those relevant to the layout.apps configuration.
function M.hideAllWindowsExcept(layoutApps, allApps)
  local allowedIds = {}
  for name,_ in pairs(layoutApps) do
    table.insert(allowedIds, allApps[name].id)
  end
  for _,window in pairs(hs.window.visibleWindows()) do
    local app = window:application()
    local found = hs.fnutils.find(allowedIds, function(allowedId)
      return allowedId == app:bundleID()
    end)
    if not found then
      app:hide()
    end
  end
end

-- List apps in cells
function M.listAppsInCells(layout, state)
  local cells = {}

  for key,_ in pairs(layout.cells) do
    cells[key] = {
      ['key'] = key,
      ['apps'] = {},
    }
  end

  for app,config in pairs(layout.apps) do
    table.insert(cells[config.cell].apps, app)
  end

  for _,config in pairs(state.layout_customizations[state.current_layout_key] or {}) do
    table.insert(cells[config.cell].apps, config.window:application():name()..' ('..config.window:title()..', '..config.window:id()..')')
  end

  return cells
end

return M

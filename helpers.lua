local M = {}

-- Extra grid helper, which maybe we can PR to hammerspoon and/or remove later.
M.grid = dofile(hs.spoons.resourcePath('grid.lua'))

-- Apply layout.
function M.applyLayout(key, variant, state)
  if key then state.current_layout_key = key end
  if variant then state.current_layout_variant = variant end

  local layout = state.layouts[state.current_layout_key]

  if layout.apps then
    M.ensureOpenWhenConfigured(layout.apps, state.apps)
    M.hideAllWindowsExcept(layout.apps, state.apps)
  end

  local elements = M.normalizeLayoutForApply(layout, state)

  for _,custom in pairs(state.layout_customizations[state.current_layout_key] or {}) do
    table.insert(elements, M.normalizeElementForApply(custom.app_id, custom.window, custom.cell, layout, state))
  end

  hs.layout.apply(elements)
end

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
    if app then
      app:unhide()
    end
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

  for key,config in pairs(state.layout_customizations[state.current_layout_key] or {}) do
    if config.window:application() then
      table.insert(cells[config.cell].apps, config.window:application():name()..' ('..config.window:title()..', '..config.window:id()..')')
    else
      state.layout_customizations[state.current_layout_key][key] = nil
      print("cleaned up non-existent window layout config")
      -- TODO: Extract config validate and cleanup logic, so that this can be used elsewhere
    end
  end

  return cells
end

-- Normalize layouts
function M.normalizeLayouts(layouts)
  local normalized = layouts or {}

  -- Normalize cell strings to variant-friendly tables
  for layoutKey,layout in ipairs(layouts or {}) do
    local cells = {}
    for _,cell in ipairs(layout.cells or {}) do
      table.insert(cells, type(cell) == "string" and { cell } or cell)
    end
    normalized[layoutKey].cells = cells
  end

  return normalized
end

return M

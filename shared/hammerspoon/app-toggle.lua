local M = {}

local currentApp = "ghostty"
local currentBundleID = nil


local function getApp()
  local app = nil
  if currentBundleID then
    app = hs.application.get(currentBundleID)
  end
  if not app then
    app = hs.application.get(currentApp)
  end
  return app
end

local function launchApp()
  if currentBundleID then
    hs.application.launchOrFocusByBundleID(currentBundleID)
  else
    hs.application.launchOrFocus(currentApp)
  end
end

local function toggleAppVisibility()
  local app = getApp()
  if app then
    if not app:mainWindow() then
      if currentApp == "kitty" then
        app:selectMenuItem({ "kitty", "New OS window" })
      else
        launchApp()
      end
    elseif app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    launchApp()
    hs.timer.doAfter(0.5, function()
      local newApp = getApp()
      if newApp and newApp:mainWindow() then
        newApp:mainWindow():maximize()
      end
    end)
  end
end

local function toggleAppMonitor()
  local app = getApp()
  if app and app:mainWindow() then
    local win = app:mainWindow()
    local screens = hs.screen.allScreens()

    if #screens > 1 then
      local currentScreen = win:screen()
      local nextScreen

      for i, screen in ipairs(screens) do
        if screen ~= currentScreen then
          nextScreen = screen
          break
        end
      end

      if nextScreen then
        win:moveToScreen(nextScreen)
        win:maximize()
        app:activate()
      end
    else
      win:maximize()
      app:activate()
    end
  else
    launchApp()
  end
end

local function handleAppResize()
  local app = getApp()
  if not app then
    return
  end

  local mainWindow = app:mainWindow()
  if not mainWindow then
    return
  end

  if #hs.screen.allScreens() > 1 then
    toggleAppMonitor()
  else
    mainWindow:maximize()
  end
end

local screenWatcher

local function setCurrentApp(appName, bundleID)
  if appName and appName ~= "" then
    currentApp = appName
    currentBundleID = bundleID
    hs.alert.show("Toggle app set to: " .. currentApp)
  end
end

local function getCurrentApp()
  return currentApp
end

local function setCurrentAppFromFocused()
  local focusedApp = hs.application.frontmostApplication()
  if focusedApp then
    local appName = focusedApp:name()
    local bundleID = focusedApp:bundleID()
    setCurrentApp(appName, bundleID)
  else
    hs.alert.show("No app currently focused")
  end
end

local function startResizeWatcher()
  if screenWatcher then
    screenWatcher:stop()
  end

  screenWatcher = hs.screen.watcher.new(function()
    hs.timer.doAfter(0.5, handleAppResize)
  end)
  screenWatcher:start()
end

M.toggleVisibility = toggleAppVisibility
M.toggleMonitor = toggleAppMonitor
M.setCurrentApp = setCurrentApp
M.getCurrentApp = getCurrentApp
M.setCurrentAppFromFocused = setCurrentAppFromFocused
M.startResizeWatcher = startResizeWatcher

return M

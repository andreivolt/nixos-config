require("hs.ipc")

local appToggle = require("app-toggle")
local darkmode = require("darkmode")

hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall:updateAllRepos()

spoon.SpoonInstall:andUse("ReloadConfiguration", {
  repo = "default",
  watch_paths = { hs.configdir },
})
spoon.ReloadConfiguration:start()

-- Main toggle hotkeys
hs.hotkey.bind({}, "²", appToggle.toggleVisibility)
hs.hotkey.bind({ "alt" }, "²", appToggle.toggleMonitor)

-- Set the currently focused app as the toggle target
hs.hotkey.bind({ "cmd", "alt" }, "²", appToggle.setCurrentAppFromFocused)

-- Other hotkeys
hs.hotkey.bind({ "ctrl", "cmd" }, "v", function()
  hs.execute("/Users/andrei/bin/vision -c", true)
end)
hs.hotkey.bind({ "ctrl", "cmd" }, "d", darkmode.toggleDarkMode)

-- Start resize watcher
appToggle.startResizeWatcher()

hs.ipc.cliInstall()

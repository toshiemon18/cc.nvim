local M = {}

-- Re-export the renderer functionality
local renderer = require("cc_nvim.ui.diff.renderer")

M.open = renderer.open
M.close = renderer.close
M.toggle = renderer.toggle
M.refresh = renderer.refresh
M.setup = renderer.setup

return M
-- dynamic_cursors.lua
-- Plugin config for hypr-dynamic-cursors.
-- In the new Lua API, plugin options live under their plugin name in hl.config().

hl.config({
  ["dynamic-cursors"] = {
    enabled   = true,
    mode      = "stretch",
    threshold = 2,

    shake = {
      enabled = false,
    },

    stretch = {
      limit    = 500,
      ["function"] = "quadratic",  -- 'function' is a Lua keyword, needs quoting
      window   = 120,
    },
  },
})

-- The detecting of undeclared vars is discussed on:
-- http://www.lua.org/pil/14.2.html
-- http://lua-users.org/wiki/DetectingUndefinedVariables

local IGNORED_EXTRAS
local IGNORED_WRITES = {}
local IGNORED_READS  = {
  _PROMPT=true,
  _PROMPT2=true,
}

local MT = {
  __index = function (table, key)
    if IGNORED_READS[key] then
      return
    end
    error("attempt to read undeclared variable: "..key, 2)
  end,

  __newindex = function (table, key, value)
    if not (IGNORED_WRITES[key] or IGNORED_EXTRAS[key]) then
      local info = debug.getinfo(2, "Sl")
      MAD.warn("%s:%s: write to undeclared global variable: %s\n",
               tostring(info.short_src), tostring(info.currentline), key)
    end
    rawset(table, key, value)
  end,
}

local require_orig = require

local function require_mod (modname)
  IGNORED_WRITES[modname] = true
  return origRequire(modname)
end

-- Raises an error when an undeclared variable is read or written.
local function strict (extra)
  local mt = getmetatable(_G)
  if mt ~= nil and mt ~= MT then
    error("a global metatable already exists")
  end
  setmetatable(_G, MT)
  IGNORED_EXTRAS = extra or {}
  require = require_mod
end

local function unstrict ()
  local mt = getmetatable(_G)
  if mt ~= nil and mt ~= MT then
    error("invalid global metatable (i.e. not set by strict)")
  end
  setmetatable(_G, nil)
  IGNORED_EXTRAS = nil
  require = require_orig
end

return {
  strict   = strict,
  unstrict = unstrict,
}

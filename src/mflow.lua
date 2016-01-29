--[=[
 o----------------------------------------------------------------------------o
 |
 | Map Flow module
 |
 | Methodical Accelerator Design - Copyright CERN 2015
 | Support: http://cern.ch/mad  - mad at cern.ch
 | Authors: L. Deniau, laurent.deniau at cern.ch
 | Contrib: -
 |
 o----------------------------------------------------------------------------o
 | You can redistribute this file and/or modify it under the terms of the GNU
 | General Public License GPLv3 (or later), as published by the Free Software
 | Foundation. This file is distributed in the hope that it will be useful, but
 | WITHOUT ANY WARRANTY OF ANY KIND. See http://gnu.org/licenses for details.
 o----------------------------------------------------------------------------o
  
  Purpose:
  - provides constructors and functions for map flow

 o----------------------------------------------------------------------------o
]=]

local M = { __help = {}, __test = {} }

-- help ----------------------------------------------------------------------o

M.__help.self = [[
NAME
  mflow -- Map Flow module

SYNOPSIS
  local mflow = require 'mflow'

DESCRIPTION
  The module mflow provides consistent definitions and constructors of map
  flow handling vector or reals and real GTPSAs.

RETURN VALUES
  The constructors of map flow.

SEE ALSO
  gmath, complex, matrix, cmatrix, tpsa, ctpsa
]]

-- modules -------------------------------------------------------------------o

local gmath   = require 'gmath'
local tpsa    = require 'tpsa'
local xtpsa   = require 'xtpsa'
local complex = require 'complex'

local desc  = xtpsa.desc
local mono  = xtpsa.mono

-- locals --------------------------------------------------------------------o

local type, insert = type, table.insert
local isnum, iscpx, isscl, ident, isatpsa, tostring =
      gmath.is_number, gmath.is_complex, gmath.is_scalar, gmath.ident,
      gmath.isa_tpsa, gmath.tostring

local D = {}  -- private desc
local C = {}  -- private ctor
local V = {}  -- private keys
local T = {}  -- temporary keys

local S_lst = {x=1, px=1, y=1, py=1, t=1, pt=1} -- allowed variable names
local S_dft = {x=1, px=1, y=1, py=1, t=1, pt=1} -- default variable names

-- implementation ------------------------------------------------------------o

local function make_map(args, num, tpsa)
  if args.v then
    for _,v in ipairs(args.v) do
      assert(S_lst[v], "invalid variable name")
    end
  else args.v = S_dft end

  local var = args.v
  local mo  = args.mo or args.vo
  local d   = false

  for i=1,#mo do
    if mo[i] > 0 then d = true ; break end
  end

  local dsc = d and desc(args) or {nmv=#mo} -- TODO
  local map = { [D]=dsc, [C]=tpsa, [V]={}, [T]={} }

  for i=1,dsc.nmv do
    map[V][i] = var[i]
    if mo[i] == 0 then
      map[V][var[i]] = num(0)
    else
      map[V][var[i]] = tpsa(dsc, mo[i])
    end
  end

  return setmetatable(map, M)
end

local function map(args)
  return make_map(args, ident, tpsa)
end

local function cmap(args)
  return make_map(args, complex, ctpsa)
end

-- initialization ------------------------------------------------------------o

function M.clear(map)  -- clear tempory variables
  for i,k in ipairs(map[T]) do
    map[T][i], map[T][k] = nil, nil
  end
  return map
end

function M.init(map, tbl)
  for i,k in ipairs(map[V]) do
    if isscl(map[V][k]) then
      map[V][k] = tbl[i]
    else -- tpsa
      map[V][k]:set0(tbl[i])
      map[V][k]:set_sp({i,1}, 1)
    end
  end
  return map
end

-- access --------------------------------------------------------------------o

function M.get(map, var, mono)
  return isscl(map[var]) and map[var] or map[var]:get(mono)
end

function M.set(map, var, mono, val)
  val = val or mono
  if isscl(map[var]) then
    map[var] = val
  else
    map[var]:set(mono, val)
  end
  return map
end

function M.gtrunc(map, ...)
  local to, mo = -1
  for _,v in ipairs{...} do
    mo = isscl(v) and 0 or v.mo
    to = mo > to and mo or to
  end
  map[D].trunc = mo and to or map[D].mo
  return map
end

-- indexing ------------------------------------------------------------------o

function M.__index (map, key)
--  io.write("getting ", key, '\n')
  return map[V][key] or map[T][key] or M[key]
end

function M.__newindex (map, key, val)
--  io.write("setting ", key, '\n')
  local K = map[V][key] and V or T
  local v = map[K][key]         -- get variable

  if v == nil then              -- create tmp variable
    map[T][#map[T]+1] = key
    map[T][key]       = val
  elseif isscl(v) then          -- scalar or tpsa -> scalar
    map[K][key] = isscl(val) and val or val.coef[0]
  elseif isscl(val) then
    v:scalar(val)               -- scalar -> TPSA
  else
    val:copy(v)                 -- TPSA -> TPSA
  end
end

-- I/O -----------------------------------------------------------------------o

local function print_map(map)
  for _,name in ipairs(map) do
    local var = map[name]
    io.write(name, ': ')
    if isnum(var) then
      io.write(var, '\n')
    else
      var:print()
      io.write('\n')
    end
  end
  return map
end

function M.print_tmp(map)
  return print_map(map[T])
end

function M.print(map)
  return print_map(map[V])
end

------------------------------------------------------------------------------o

return {
  map  = map,
  cmap = cmap
}

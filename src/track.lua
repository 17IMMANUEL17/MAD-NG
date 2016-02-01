--[=[
 o----------------------------------------------------------------------------o
 |
 | Track module
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
  - TODO
  
 o----------------------------------------------------------------------------o
]=]

local M = { __help = {}, __test = {} }

-- MAD -----------------------------------------------------------------------o

M.__help.self = [[
NAME
  track -- build MAD element dynamical maps and track command

SYNOPSIS
  track = require "track"

DESCRIPTION
  The module track provides...

RETURN VALUES
  The track command

SEE ALSO
  element
]]
 
-- requires ------------------------------------------------------------------o

local E = require 'element'
local T = require 'tfstable'

local tpsa = require 'tpsa' -- "lib.tpsaFFI"
local map  = require 'mflow'

-- locals --------------------------------------------------------------------o

local is_number = function(a)
  return type(a) == "number"
end

local get0 = function(a)
  return is_number(a) and a or a:get0()
end

local sqrt = function(a)
  return is_number(a) and math.sqrt(a) or a:sqrt()
end

local same = function(a, b)
  return is_number(a) and a or a:same(b)
end

local scalar = function(a, b) -- in place
  if not is_number(a) then
    a:scalar(b)
  else
    a = b
  end
  return a
end

-- functions -----------------------------------------------------------------o

local function track_drift(e, m)
  local L, iB, T = e.length, m.beta0_inv, m.total_path
  m.lpz = L/sqrt(1 + 2*iB*m.pt + m.pt^2 - m.px^2 - m.py^2)
  m.x   = m.x + m.px * m.lpz
  m.y   = m.y + m.py * m.lpz
  m.t   = m.t + (iB + m.pt) * m.lpz - (1-T)*L*iB
end

local function track_kick(e, m)
    local iB, byt = m.beta0_inv
    local  knl,  ksl = e.knl or {}, e.ksl or {}
    local kn0l, ks0l = knl[1] or 0, ksl[1] or 0
    local nmul = math.max(#knl, #ksl)

    m.by = scalar(m.by or same(m.px), knl[nmul] or 0)
    m.bx = scalar(m.bx or same(m.py), ksl[nmul] or 0)

    for j=nmul-1,1,-1 do
        byt = m.x * m.by - m.y * m.bx + (knl[j] or 0)
      m.bx  = m.y * m.by + m.x * m.bx + (ksl[j] or 0)
      m.by  = byt
    end

    -- tranverse kicks
    m.px = m.px - m.by + kn0l
    m.py = m.py + m.bx

    -- longitudinal time
    if kn0l ~= 0 or ks0l ~= 0 then
      m.pz = sqrt( 1 + 2*iB*m.pt + m.pt^2 )
      m.t = m.t + ( kn0l * m.x - ks0l * m.y ) * (iB + m.pt) / m.pz
    end
end

-- load track maps into elements

E.element.track = function (self, map)
  track_drift(self, map)
  return self.s_pos + self.length
end

E.multipole.track = function (self, map)
  track_kick(self, map)
  return self.s_pos + self.length
end

-- track table

M.table = function (name)
  name = name or 'track'
  local tbl = T(name) ({{'name'}, 's', 'length', 'x', 'px', 'y', 'py', 't', 'pt'})
  tbl:set_key{ type='track' }
  return tbl
end

-- track command
-- track { seq=seqname, tbl=tblname, map=map }

M.track = function (info)
  local seq = info.seq or error("invalid sequence")
  local map = info.map or error("invalid map to track")
  local tbl = info.tbl and M.table(info.tbl) or nil
  local dft =  { name='dft', idx=1, length=1 } -- drift for local use

  --io.write('tracking map:\n')
  --map:print()

  -- dynamical thin tracking
  local end_pos = seq[1].s_pos + seq[1].length -- $start marker

  for i=1,#seq do
    local e = seq[i]
    local ds = e.s_pos - end_pos

    -- implicit drift with L = ds
    if ds > 1e-8 then
      dft.name = 'dft_' .. dft.idx
      dft.length = ds
      dft.idx = dft.idx + 1
      track_drift(dft, map)
      end_pos = end_pos + ds

      if tbl ~= nil then
        tbl = tbl + { name=dft.name, s=end_pos, length=ds,
                      x=get0(map.x), px=get0(map.px), y=get0(map.y), py=get0(map.py), t=get0(map.t), pt=get0(map.pt) }
      end
    elseif ds < 0 then
      error("negative drift detected before element " .. e.name)
    end

    -- sequence element
    end_pos = e:track(map)

    -- fill the table, should be moved to a 'table' element
    if tbl ~= nil then
      tbl = tbl + { name=e.name, s=e.s_pos, length=e.length,
                    x=get0(map.x), px=get0(map.px), y=get0(map.y), py=get0(map.py), t=get0(map.t), pt=get0(map.pt) }
    end
  end

  return tbl
end

-- end -----------------------------------------------------------------------o

return M

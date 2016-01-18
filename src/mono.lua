--[=[
 o----------------------------------------------------------------------------o
 |
 | Monomial module
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
  - provides types and constructors to monomials

  Information:
  - this module is used by desc, tpsa and ctpsa modules.

 o----------------------------------------------------------------------------o
]=]

local M = { __help = {}, __test = {} }

-- help ----------------------------------------------------------------------o

M.__help.self = [[
NAME
  mono -- Monomial contructors and operations

DESCRIPTION
  The module mono provides constructors and operations on monomials.

RETURN VALUES
  The constructors of monomials.

SEE ALSO
  tpsa, ctpsa
]]

-- modules -------------------------------------------------------------------o

local ffi  = require 'ffi'
local clib = require 'cmad'

local tbl_new = require 'table.new'

-- ffi -----------------------------------------------------------------------o

ffi.cdef[[
typedef struct mono mono_t;

struct mono {
  int   n;
  ord_t ord[?];
};
]]

-- locals --------------------------------------------------------------------o

local istype = ffi.istype

-- FFI type constructors
local mono_ctor = ffi.typeof('mono_t')

-- implementation ------------------------------------------------------------o

local function isnum(x)
  return type(x) == 'number'
end

local function is_table(x)
  return type(x) == 'table'
end

local function mono_alloc(n)
  local r = mono_ctor(n)
  r.n = n
  return r
end

-- mono(tbl)
-- mono(val, len)

local function mono (m, n_)
  local n = is_table(m) and #m or n_
  local r = mono_alloc(n)
  if is_table(m) then
    for i=1,n   do r.ord[i-1] = m[i] end
  else
    for i=0,n-1 do r.ord[i-1] = m    end
  end
  return r
end

function M.size (a)
  return a.n
end

function M.fill (r, v)
  clib.mad_mono_fill(r.n, r.ord, v)
  return r
end

function M.copy (a, r_)
  local r = r_ or mono_alloc(a.n)
  assert(a.n == r.n, "incompatible monomials")
  clib.mad_mono_copy(a.n, a.ord, r.ord)
  return r
end

function M.max (a)
  return clib.mad_mono_max(a.n, a.ord)
end

function M.ord (a)
  return clib.mad_mono_ord(a.n, a.ord)
end

function M.equ (a, b)
  assert(a.n == b.n, "incompatible monomials")
  return clib.mad_mono_equ(a.n, a.ord, b.ord)
end

function M.leq (a, b)
  assert(a.n == b.n, "incompatible monomials")
  return clib.mad_mono_leq(a.n, a.ord, b.ord)
end

function M.add (a, b, r_)
  local r = r_ or mono_alloc(a.n)
  assert(a.n == b.n and a.n == r.n, "incompatible monomials")
  clib.mad_mono_add(a.n, a.ord, b.ord, r.ord)
  return r
end

function M.sub (a, b, r_)
  local r = r_ or mono_alloc(a.n)
  assert(a.n == b.n and a.n == r.n, "incompatible monomials")
  clib.mad_mono_sub(a.n, a.ord, b.ord, r.ord)
  return r
end

function M.concat (a, b, r_)
  local r = r_ or mono_alloc(a.n+b.n)
  assert(a.n+b.n == r.n, "incompatible monomials")
  clib.mad_mono_concat(a.n, a.ord, b.n, b.ord, r.ord)
  return r
end

function M.tostring (a, sep_)
  local n = a:size()
  local r = tbl_new(n,0)
  for i=1,n do r[i] = tostring(a.ord[i-1]) end
  return table.concat(r, sep_ or ' ')
end

M.__eq       = M.equ
M.__le       = M.leq
M.__add      = M.add
M.__sub      = M.sub
M.__len      = M.size
M.__concat   = M.concat
M.__tostring = M.tostring

M.__lt = function (a, b) return a <= b and a ~= b end

-- monomial-as-array behavior, unchecked bounds
M.__index = function (a, idx)
  return isnum(idx) and a.ord[idx] or M[idx]
end
M.__newindex = function (a, idx, val)
  a.ord[idx] = val
end

ffi.metatype('mono_t', M)

------------------------------------------------------------------------------o
return mono

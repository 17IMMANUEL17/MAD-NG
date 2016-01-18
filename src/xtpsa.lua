--[=[
 o----------------------------------------------------------------------------o
 |
 | TPSA constructor module
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
  - provides types and constructors to tpsa

  Information:
  - this module is loaded by tpsa and ctpsa modules. It should not be loaded
    by users.

 o----------------------------------------------------------------------------o
]=]

local M = { __help = {}, __test = {} }

-- help ----------------------------------------------------------------------o

M.__help.self = [[
NAME
  xtpsa -- GTPSA contructors

SYNOPSIS
  This module should not be loaded directly.

DESCRIPTION
  The module xtpsa provides consistent definitions and constructors of
  real GTPSA and complex GTPSA.

RETURN VALUES
  The constructors of real GTPSA, complex GTPSA and GTPSA descriptor.

SEE ALSO
  tpsa, ctpsa
]]

-- modules -------------------------------------------------------------------o

local ffi   = require 'ffi'
local clib  = require 'cmad'
local mono  = require 'mono'
local gmath = require 'gmath'

-- ffi -----------------------------------------------------------------------o

ffi.cdef[[
typedef unsigned int bit_t; // mad_bit.h

struct desc { // warning: must be kept identical to C definition
  int   id;
  int   nmv, nv, nc;
  ord_t mo, ko, trunc;
};

struct tpsa { // warning: must be kept identical to C definition
  desc_t *d;
  ord_t   lo, hi, mo;
  bit_t   nz;
  num_t   coef[?];
};

struct ctpsa { // warning: must be kept identical to C definition
  desc_t *d;
  ord_t   lo, hi, mo;
  bit_t   nz;
  cnum_t  coef[?];
};
]]

-- locals --------------------------------------------------------------------o

local istype = ffi.istype
local min, max = math.min, math.max

-- FFI type constructors
local  tpsa_ctor = ffi.typeof( 'tpsa_t')
local ctpsa_ctor = ffi.typeof('ctpsa_t')
local  strs_ctor = ffi.typeof('str_t[?]')

-- implementation ------------------------------------------------------------o

local function is_table(x)
  return type(x) == 'table'
end

local function is_desc(x)
  return type(x) == 'cdata' and istype('desc_t', x)
end

function gmath.is_tpsa (x)
  return type(x) == 'cdata' and istype('tpsa_t', x)
end

function gmath.is_ctpsa (x)
  return type(x) == 'cdata' and istype('ctpsa_t', x)
end

function gmath.isa_tpsa (x)
  return type(x) == 'cdata' and (istype('tpsa_t', x) or istype('ctpsa_t', x))
end

local isa_tpsa = gmath.isa_tpsa

local function tpsa_alloc (d, mo)
  local nc, tpsa = d.nc, nil
  if nc < clib.mad_alloc_threshold then
    tpsa = tpsa_ctor(nc)
  else
    local siz = ffi.sizeof('tpsa_t', nc)
    local ptr = clib.mad_malloc(siz)
    tpsa = ffi.gc(ffi.cast('tpsa_t&', ptr), clib.mad_free)
  end
  tpsa.d = d
  tpsa.lo, tpsa.hi, tpsa.mo = mo, 0, mo
  tpsa.nz, tpsa.coef[0] = 0, 0
  return tpsa
end

local function ctpsa_alloc (d, mo)
  local nc, ctpsa = d.nc, nil
  if nc < (clib.mad_alloc_threshold/2) then
    ctpsa = ctpsa_ctor(nc)
  else
    local siz = ffi.sizeof('ctpsa_t', nc)
    local ptr = clib.mad_malloc(siz)
    ctpsa = ffi.gc(ffi.cast('ctpsa_t&', ptr), clib.mad_free)
  end
  ctpsa.d = d
  ctpsa.lo, ctpsa.hi, ctpsa.mo = mo, 0, mo
  ctpsa.nz, ctpsa.coef[0] = 0, 0
  return ctpsa
end

-- tpsa(t)       -> t.mo
-- tpsa(d)       -> d.mo
-- tpsa(t|d, mo) -> mo

local function tpsa (t, mo_)
  if isa_tpsa(t) then
    return tpsa_alloc(t.d, mo_ and max(0,min(mo_,t.d.mo)) or t.mo)
  elseif is_desc(t) then
    return tpsa_alloc(t  , mo_ and max(0,min(mo_,t  .mo)) or t.mo)
  else
    error("invalid argument to tpsa constructor, expecting TPSA or descriptor")
  end
end

local function ctpsa (t, mo_)
  if isa_tpsa(t) then
    return ctpsa_alloc(t.d, mo_ and max(0,min(mo_,t.d.mo)) or t.mo)
  elseif is_desc(t) then
    return ctpsa_alloc(t  , mo_ and max(0,min(mo_,t  .mo)) or t.mo)
  else
    error("invalid argument to ctpsa constructor, expecting TPSA or descriptor")
  end
end

-- nv: number of variables (if vo is a value)
-- vo: variables orders (array or value)
-- mo: map variables orders with mo[i] > vo[i]
-- nk: number of knobs (if ko is a value)
-- ko: knobs orders (array or value)
-- dk: max knobs 'cross' orders (degres)
-- ex0: {nv=2,vo=2 [, mo=3]}
-- ex1: {vo={2,2} [, mo={3,3}] [, v={'x', 'px'}] [, ko={1,1,1}] [, dk=2]}
-- ex2: {vo={2,2} [, mo={3,3}] [, v={'x', 'px'}] [, nk=3,ko=1] [, dk=2]}

local function desc (args)
  assert(args and args.vo, "not enough arguments for TPSA descriptor")

  local nv = args.nv or is_table(args.vo) and #args.vo or 0
  local nk = args.nk or is_table(args.ko) and #args.ko or 0

  assert(nv > 0, "invalid number of variables")

  local cvar =             mono(args.vo, nv)
  local cmap = args.mo and mono(args.mo, nv)
  local cknb = args.ko and mono(args.ko, nk)
  local names

  if args.v then
    names = strs_ctor(nv)
    for i=1,nv do names[i-1] = args.v[i] end
  end

  if nk > 0 then
    return clib.mad_tpsa_desc_newk(nv, cvar.ord, cmap.ord, names, nk, cknb.ord, args.dk or 0)
  else
    return clib.mad_tpsa_desc_new (nv, cvar.ord, cmap.ord, names)
  end
end

------------------------------------------------------------------------------o
return {
   tpsa =  tpsa,
  ctpsa = ctpsa,
   desc =  desc,
   mono =  mono,
}

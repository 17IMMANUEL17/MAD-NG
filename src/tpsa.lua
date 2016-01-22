--[=[
 o----------------------------------------------------------------------------o
 |
 | GTPSA module (real)
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
  - provides full set of functions and operations on real GTPSA

 o----------------------------------------------------------------------------o
]=]

local M = { __help = {}, __test = {} }

-- help ----------------------------------------------------------------------o

M.__help.self = [[
NAME
  tpsa

SYNOPSIS
  local tpsa = require 'tpsa'

DESCRIPTION
  The module tpsa implements the operators and math functions on GTPSA.

RETURN VALUES
  The constructor of real GTPSA

SEE ALSO
  gmath, complex, matrix, cmatrix, ctpsa
]]
 
-- modules -------------------------------------------------------------------o

local ffi   = require 'ffi'
local clib  = require 'cmad'
local gmath = require 'gmath'
local xtpsa = require 'xtpsa'

-- locals --------------------------------------------------------------------o

local istype, cast, sizeof, fill = ffi.istype, ffi.cast, ffi.sizeof, ffi.fill
local min, max = math.min, math.max
local isnum, isint, istable, istpsa, isctpsa =
      gmath.is_number, gmath.is_integer, gmath.is_table,
      gmath.is_tpsa, gmath.is_ctpsa

-- FFI type constructors
local tpsa  = xtpsa.tpsa
local desc  = xtpsa.desc
local mono  = xtpsa.mono

local int_arr   = ffi.typeof '      int[?]'
local int_carr  = ffi.typeof 'const int[?]'

local tpsa_arr  = ffi.typeof       'tpsa_t* [?]'
local tpsa_carr = ffi.typeof 'const tpsa_t* [?]'

-- implementation ------------------------------------------------------------o

M.tpsa = tpsa

function M.mono (t, tbl_)
  return mono(tbl_ or t.d.nv)
end

-- initialization ------------------------------------------------------------o

function M.copy (t, r_)
  local r = r_ or tpsa(t)
  clib.mad_tpsa_copy(t, r)
  return r
end

function M.complex (re_, im_, r_)
  local re, im = re_ or im_, im_ or re_
  local r = r_ or ctpsa(re, max(re.mo, im.mo))
  clib.mad_tpsa_complex(re_, im_, r)
  return r
end

M.clear  = clib.mad_tpsa_clear
M.scalar = clib.mad_tpsa_scalar

-- indexing ------------------------------------------------------------------o

function M.get_idx (t,tbl)
  local m = istable(tbl) and mono(tbl) or tbl
  return clib.mad_tpsa_midx(t, m.n, m.ord)
end

function M.get_idx_sp (t,tbl)
  -- tbl = {idx1, ord1, idx2, ord2, ... }
  local n = #tbl
  local m = int_carr(n)
  for i=1,n do m[i-1] = tbl[i] end
  return clib.mad_tpsa_midx_sp(t, n, m)
end

function M.get_mono (t, i, r_)
  local  m = r_ or t:mono()
  return m, clib.mad_tpsa_mono(t, m.n, m.ord, i)
end

-- peek & poke ---------------------------------------------------------------o

M.get0 = clib.mad_tpsa_get0

function M.get (t, m)
  if isnum(m) then
    return clib.mad_tpsa_geti(t, m)
  end
  m = istable(m) and mono(m) or m
  return clib.mad_tpsa_getm(t, m.n, m.ord)
end

function M.get_sp (t, tbl)
  -- tbl = {idx1, ord1, idx2, ord2, ... }
  local n = #tbl
  local m = int_carr(n)
  for i=1,n do m[i-1] = tbl[i] end
  return clib.mad_tpsa_getm_sp(t, n, m)
end

function M.set0 (t, a, b)
  if b == nil then a, b = 0, a end
  clib.mad_tpsa_set0(t, a, b)
end

function M.set (t, m, a, b)
  if b == nil then a, b = 0, a end
  if isnum(m) then
    clib.mad_tpsa_seti(t, m, a, b)
  end
  m = istable(m) and mono(m) or m
  clib.mad_tpsa_setm(t, m.n, m.ord, a, b)
end

function M.set_sp (t, tbl, a, b)
  if b == nil then a, b = 0, a end
  -- tbl = {idx1, ord1, idx2, ord2, ... }
  local n = #tbl
  local m = int_carr(n)
  for i=1,n do m[i-1] = tbl[i] end
  clib.mad_tpsa_setm_sp(t, n, m, a, b)
end

-- unary operators -----------------------------------------------------------o

function M.unm (t, r_)
  local r = r_ or tpsa(t)
  clib.mad_tpsa_scl(t, -1, r)
end

function M.abs (t, r_)
  local r = r_ or tpsa(t)
  clib.mad_tpsa_abs(t,r)
end

M.nrm1 = clib.mad_tpsa_nrm1
M.nrm2 = clib.mad_tpsa_nrm2

function M.der (t, ivar, r_)
  local r = r_ or tpsa(t)
  clib.mad_tpsa_der(t, r, ivar)
  return r
end

function M.mder (t, tbl, r_)
  local r = r_ or tpsa(t)
  local m = mono(tbl)
  clib.mad_tpsa_mder(t, r, m.n, m.ord)
  return r
end

function M.scale (t, val, r_)
  local r = r_ or tpsa(t)
  clib.mad_tpsa_scl(t, val, r)
  return r
end

-- binary operators ----------------------------------------------------------o

function M.add (a, b, r_)
  local r
  if isnum(a) then       -- num + tpsa
    if b.hi == 0 then return a + b.coef[0] end
    r = b:copy(r_)
    clib.mad_tpsa_set0(r, 1, a)
  elseif isnum(b) then   -- tpsa + num
    if a.hi == 0 then return a.coef[0] + b end
    r = a:copy(r_)
    clib.mad_tpsa_set0(r, 1, b)
  elseif istpsa(b) then  -- tpsa + tpsa
    r = r_ or tpsa(a, max(a.mo,b.mo))
    clib.mad_tpsa_add(a, b, r)
  else error("invalid GTPSA (+) operands") end
  return r
end

function M.sub (a, b, r_)
  local r
  if isnum(a) then       -- num - tpsa
    if b.hi == 0 then return a - b.coef[0] end
    r = r_ or tpsa(b)
    clib.mad_tpsa_scl (b, -1, r)
    clib.mad_tpsa_set0(r,  1, a)
  elseif isnum(b) then   -- tpsa - num
    if a.hi == 0 then return a.coef[0] - b end
    r = a:copy(r_)
    clib.mad_tpsa_set0(r, 1, -b)
  elseif istpsa(b) then  -- tpsa - tpsa
    r = r_ or tpsa(a, max(a.mo,b.mo))
    clib.mad_tpsa_sub(a, b, r)
  else error("invalid GTPSA (-) operands") end
  return r
end

function M.mul (a, b, r_)
  local r
  if isnum(a) then       -- num * tpsa
    if b.hi == 0 then return a * b.coef[0] end
    r = r_ or tpsa(b)
    clib.mad_tpsa_scl(b, a, r)
  elseif isnum(b) then   -- tpsa * num
    if a.hi == 0 then return a.coef[0] * b end
    r = r_ or tpsa(a)
    clib.mad_tpsa_scl(a, b, r)
  elseif istpsa(b) then  -- tpsa * tpsa
    r = r_ or tpsa(a, max(a.mo,b.mo))
    clib.mad_tpsa_mul(a, b, r)
  else error("invalid GTPSA (*) operands") end
  return r
end

function M.div (a, b, r_)
  local r
  if isnum(a) then       -- num / tpsa
    if b.hi == 0 then return a / b.coef[0] end
    r = r_ or tpsa(b)
    clib.mad_tpsa_inv(b, a, r)
  elseif isnum(b) then   -- tpsa / num
    if a.hi == 0 then return a.coef[0] / b end
    r = r_ or tpsa(a)
    clib.mad_tpsa_scl(a, 1/b, r)
  elseif istpsa(b) then  -- tpsa / tpsa
    r = r_ or tpsa(a, max(a.mo,b.mo))
    clib.mad_tpsa_div(a, b, r)
  else error("invalid GTPSA (/) operands") end
  return r
end

function M.pow (a, n, r_)
  assert(istpsa(a) and isint(n), "invalid GTPSA (^) operands")
  if a.hi == 0 then return a.coef[0] ^ n end
  local r = r_ or tpsa(a)
  clib.mad_tpsa_ipow(a, r, n)
  return r
end

function M.poisson(a, b, n, r_)
  local r = r_ or tpsa(a, max(a.mo,b.mo))
  clib.mad_tpsa_poisson(a, b, r, n)
  return r
end

-- functions -----------------------------------------------------------------o

function M.acc (a, v, r_)  -- r += v*a
  local r = r_ or tpsa(a)
  clib.mad_tpsa_acc(a, v, r)
  return r
end

function M.inv (a, v, r_)  -- v/a
  local r = r_ or tpsa(a)
  clib.mad_tpsa_inv(a, v, r)
  return r
end

function M.invsqrt (a, b, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_invsqrt(a, b, r)
  return r
end

function M.sqrt (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_sqrt(a, r)
  return r
end

function M.exp (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_exp(a, r)
  return r
end

function M.log (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_log(a, r)
  return r
end

function M.sin (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_sin(a, r)
  return r
end

function M.cos (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_cos(a, r)
  return r
end

function M.tan (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_tan(a, r)
  return r
end

function M.cot (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_cot(a, r)
  return r
end

function M.sinh (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_sinh(a, r)
  return r
end

function M.cosh (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_cosh(a, r)
  return r
end

function M.tanh (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_tanh(a, r)
  return r
end

function M.coth (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_coth(a, r)
  return r
end

function M.asin (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_asin(a, r)
  return r
end

function M.acos (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_acos(a, r)
  return r
end

function M.atan (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_atan(a, r)
  return r
end

function M.acot (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_acot(a, r)
  return r
end

function M.asinh (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_asinh(a, r)
  return r
end

function M.acosh (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_acosh(a, r)
  return r
end

function M.atanh (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_atanh(a, r)
  return r
end

function M.acoth (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_acoth(a, r)
  return r
end

function M.erf (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_erf(a, r)
  return r
end

function M.sinc (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_sinc(a, r)
  return r
end

function M.sirx (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_sirx(a, r)
  return r
end

function M.corx (a, r_)
  local r = r_ or tpsa(a)
  clib.mad_tpsa_corx(a, r)
  return r
end

function M.sincos (a, rs_, rc_)
  local rs = rs_ or tpsa(a)
  local rc = rc_ or tpsa(a)
  clib.mad_tpsa_sincos(a, rs, rc)
  return rs, rc
end

function M.sincosh (a, rs_, rc_)
  local rs = rs_ or tpsa(a)
  local rc = rc_ or tpsa(a)
  clib.mad_tpsa_sincosh(a, rs, rc)
  return rs, rc
end

-- maps ----------------------------------------------------------------------o

-- TODO: these methods should be moved to the map module

function M.compose (ma, mb, mr)
  -- ma, mb, mr -- compatible lua arrays of TPSAs
  local cma, cmb, cmr =
        tpsa_carr(#ma, ma), tpsa_carr(#mb, mb), tpsa_arr(#mr, mr)
  clib.mad_tpsa_compose(#ma, cma, #mb, cmb, #mr, cmr)
end

function M.minv (ma, mr)
  -- ma, mr -- compatible lua arrays of TPSAs
  local cma, cmc = tpsa_carr(#ma, ma), tpsa_arr(#mr, mr)
  clib.mad_tpsa_minv(#ma, cma, #mc, cmc)
end

function M.pminv (ma, mr, rows)
  -- ma, mr -- compatible lua arrays of TPSAs
  local cma, cmr = tpsa_carr(#ma, ma), tpsa_arr(#mr, mr)
  local sel = int_arr(#rows)
  for i=1,#rows do sel[i-1] = rows[i] end
  clib.mad_tpsa_pminv(#ma, cma, #mr, cmr, sel)
end

-- I/O -----------------------------------------------------------------------o

M.print = clib.mad_tpsa_print

function M.read (_, file)
  local t = tpsa(clib.mad_tpsa_scan_hdr(file))
  clib.mad_tpsa_scan_coef(t, file)
  return t
end

------------------------------------------------------------------------------o

M.__unm = M.unm
M.__add = M.add
M.__sub = M.sub
M.__mul = M.mul
M.__div = M.div
M.__pow = M.pow

ffi.metatype('tpsa_t', M)

------------------------------------------------------------------------------o
return tpsa

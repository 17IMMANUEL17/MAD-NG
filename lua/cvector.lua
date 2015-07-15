local M = { __author = 'ldeniau', __version = '2015.06', __help = {}, __test = {} }

-- MAD -------------------------------------------------------------------------

M.__help.self = [[
NAME
  cvector

SYNOPSIS
  local cvector = require 'cvector'

DESCRIPTION
  The module cvector implements the operators and math functions on
  complex vectors:
    (minus) -, +, -, *, /, %, ^, ==,
    size, sizes, get, set, zeros, ones, set_table,
    unm, add, sub, mul, div, mod, pow,
    real, imag, conj, norm, angle, inner_prod, outer_prod, cross_prod,
    abs, arg, exp, log, pow, sqrt, proj,
    sin, cos, tan, sinh, cosh, tanh,
    asin, acos, atan, asinh, acosh, atanh,
    copy, foldl, foldr, map, map2, tostring, totable.

RETURN VALUES
  The constructor of complex vectors

SEE ALSO
  math, gmath, complex, vector, matrix, cmatrix
]]
 
-- DEFS ------------------------------------------------------------------------

local ffi    = require 'ffi'
local linalg = require 'linalg'
local gm     = require 'gmath'

-- locals
local clib            = linalg.cmad
local vector, cvector = linalg.vector, linalg.cvector
local matrix, cmatrix = linalg.matrix, linalg.cmatrix

local isnum, iscpx, iscalar, isvec, iscvec, ismat, iscmat,
      real, imag, conj, ident, min,
      abs, arg, exp, log, sqrt, proj,
      sin, cos, tan, sinh, cosh, tanh,
      asin, acos, atan, asinh, acosh, atanh,
      unm, mod, pow = 
      gm.is_number, gm.is_complex, gm.is_scalar,
      gm.is_vector, gm.is_cvector, gm.is_matrix, gm.is_cmatrix,
      gm.real, gm.imag, gm.conj, gm.ident, gm.min,
      gm.abs, gm.arg, gm.exp, gm.log, gm.sqrt, gm.proj,
      gm.sin, gm.cos, gm.tan, gm.sinh, gm.cosh, gm.tanh,
      gm.asin, gm.acos, gm.atan, gm.asinh, gm.acosh, gm.atanh,
      gm.unm, gm.mod, gm.pow

local istype, sizeof, fill = ffi.istype, ffi.sizeof, ffi.fill

local cres = ffi.new 'complex[1]'

-- Lua API

function M.size  (x)       return x.n end
function M.sizes (x)       return x.n, 1 end
function M.get   (x, i)    return x.data[i-1] end
function M.set   (x, i, e) x.data[i-1] = e ; return x end

function M.zeros(x)
  fill(x.data, sizeof('complex', x:size()))
  return x
end

function M.ones (x, e_)
  local n, e = x:size(), e_ or 1
  for i=0,n-1 do x.data[i] = e end
  return x
end

function M.set_table (x, tbl)
  local n = x:size()
  assert(#tbl == n, "incompatible cvector sizes with table")
  for i=1,n do x.data[i-1] = tbl[i] end
  return x
end

function M.foldl (x, r, f)
  for i=0,x:size()-1 do r = f(r, x.data[i]) end
  return r
end

function M.foldr (x, r, f)
  for i=0,x:size()-1 do r = f(x.data[i], r) end
  return r
end

function M.map (x, f, r_)
  local n = x:size()
  local r = r_ or cvector(n)
  assert(n == r:size(), "incompatible cvector sizes")
  for i=0,n-1 do r.data[i] = f(x.data[i]) end
  return r
end

function M.map2 (x, y, f, r_)
  local n = x:size()
  local r = r_ or cvector(n)
  assert(n == y:size(), "incompatible cvector sizes")
  assert(n == r:size(), "incompatible cvector sizes")
  for i=0,n-1 do r.data[i] = f(x.data[i], y.data[i]) end
  return r
end

function M.inner_prod (x, y)
  assert(x:size() == y:size(), "incompatible cvector sizes")
  if isvec(y) then
    clib.mad_cvec_dotv(x.data, y.data, cres, x:size())
    return cres[0]
  elseif iscvec(y) then
    clib.mad_cvec_dot (x.data, y.data, cres, x:size())
    return cres[0]
  else
    error("incompatible cvector operands")
  end
end

function M.outer_prod (x, y, r_)
  local nr, nc = x:size(), y:size()
  local r = r_ or cmatrix(nr,nc)
  assert(iscmat(r), "incompatible cmatrix kinds")
  assert(nr == r:rows() and nc == r:cols(), "incompatible vector-cmatrix sizes")
  for i=1,nr do
    for j=1,nc do r:set(i,j, x:get(i)*y:get(j)) end
  end
  return r
end

function M.cross_prod (x, y, r_)
  local n = x:size()
  local r = r_ or cvector(n)
  assert(n == y:size(), "incompatible cvector sizes")
  assert(n == r:size(), "incompatible cvector sizes")
  for i=1,n-2 do
    r.data[i-1] = x.data[i] * y.data[i+1] - x.data[i+1] * y.data[i]
  end
  r.data[n-2] = x.data[n-1] * y.data[0] - x.data[0] * y.data[n-1]
  r.data[n-1] = x.data[  0] * y.data[1] - x.data[1] * y.data[  0]
  return r
end

function M.norm (x)
  return sqrt(clib.mad_cvec_dot(x.data, x.data, x:size()))
end

function M.angle (x, y)
  local w = x:inner_prod(y)
  local v = x:norm() * y:norm()
  return acos(w / v) -- [0, pi]
end

function M.copy  (x, r_)  return x:map (ident, r_) end
function M.real  (x, r_)  return x:map (real , r_) end
function M.imag  (x, r_)  return x:map (imag , r_) end
function M.conj  (x, r_)  return x:map (conj , r_) end
function M.abs   (x, r_)  return x:map (abs  , r_) end
function M.arg   (x, r_)  return x:map (arg  , r_) end
function M.exp   (x, r_)  return x:map (exp  , r_) end
function M.log   (x, r_)  return x:map (log  , r_) end
function M.sqrt  (x, r_)  return x:map (sqrt , r_) end
function M.proj  (x, r_)  return x:map (proj , r_) end
function M.sin   (x, r_)  return x:map (sin  , r_) end
function M.cos   (x, r_)  return x:map (cos  , r_) end
function M.tan   (x, r_)  return x:map (tan  , r_) end
function M.sinh  (x, r_)  return x:map (sinh , r_) end
function M.cosh  (x, r_)  return x:map (cosh , r_) end
function M.tanh  (x, r_)  return x:map (tanh , r_) end
function M.asin  (x, r_)  return x:map (asin , r_) end
function M.acos  (x, r_)  return x:map (acos , r_) end
function M.atan  (x, r_)  return x:map (atan , r_) end
function M.asinh (x, r_)  return x:map (asinh, r_) end
function M.acosh (x, r_)  return x:map (acosh, r_) end
function M.atanh (x, r_)  return x:map (atanh, r_) end
function M.unm   (x, r_)  return x:map (unm  , r_) end
function M.mod   (x, y, r_) return x:map2(y, mod, r_) end -- TODO
function M.pow   (x, y, r_) return x:map2(y, pow, r_) end -- TODO

function M.__eq (x, y)
  if iscalar(y) then
    for i=0,x:size()-1 do
      if x.data[i] ~= y then return false end
    end
    return true
  end

  if x:rows() ~= y:rows() or x:cols() ~= y:cols() then return false end
  for i=0,x:size()-1 do
    if x.data[i] ~= y.data[i] then return false end
  end
  return true
end

function M.add (x, y, r_)
  if isnum(x) then -- num + cvec => cvec + num
    local r = r_ or cvector(y:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(y:size() == r:size(), "incompatible vector sizes")
    clib.mad_cvec_addn(y.data, x, r.data, r:size())
    return r
  end

  -- iscvec(x)
  local r
  if isnum(y) then -- cvec + num
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_addn(x.data, y, r.data, r:size())
  elseif iscpx(y) then -- cvec + cpx
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_addc(x.data, y.re, y.im, r.data, r:size())
  elseif isvec(y) then -- cvec + vec
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:size(), "incompatible cvector sizes")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_addv(x.data, y.data, r.data, r:size())
  elseif iscvec(y) then -- cvec + cvec
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:size(), "incompatible cvector sizes")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_add(x.data, y.data, r.data, r:size())
  else
    error("incompatible cvector (+) operands")
  end
  return r
end

function M.sub (x, y, r_)
  if isnum(x) then -- num - cvec
    local r = r_ or vector(y:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(y:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_subn (y.data, x, r.data, r:size())
    return r
  end

  -- iscvec(x)
  local r
  if isnum(y) then -- cvec - num => cvec + -num
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_addn(x.data, -y, r.data, r:size())
  elseif iscpx(y) then -- cvec - cpx => cvec + -cpx
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_addc(x.data, -y.re, -y.im, r.data, r:size())
  elseif isvec(y) then -- cvec - vec
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:size(), "incompatible cvector sizes")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_subv(x.data, y.data, r.data, r:size())
  elseif iscvec(y) then -- cvec - cvec
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:size(), "incompatible cvector sizes")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_sub(x.data, y.data, r.data, r:size())
  else
    error("incompatible cvector (-) operands")
  end
  return r
end

function M.mul (x, y, r_)
  if isnum(x) then -- num * cvec => cvec * num
    local r = r_ or cvector(y:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(y:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_muln (y.data, x, r.data, r:size())
    return r
  end

  -- iscvec(x)
  local r
  if isnum(y) then -- cvec * num
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_muln(x.data, y, r.data, r:size())
  elseif iscpx(y) then -- cvec * cpx
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_mulc(x.data, y.re, y.im, r.data, r:size())
  elseif isvec(y) then -- cvec * vec
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:size(), "incompatible cvector sizes")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_mulv(x.data, y.data, r.data, r:size())
  elseif iscvec(y) then -- cvec * cvec
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:size(), "incompatible cvector sizes")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_mul(y.data, x.data, r.data, r:size())
  elseif ismat(y) then -- cvec * mat
    r = r_ or cvector(y:cols())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:rows(), "incompatible cvector-matrix sizes")
    assert(r:size() == y:cols(), "incompatible cvector-matrix sizes")
    clib.mad_mat_cmul(x.data, y.data, r.data, r:rows(), r:cols())
  elseif iscmat(y) then -- cvec * cmat
    r = r_ or cvector(y:cols())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == y:rows(), "incompatible cvector-cmatrix sizes")
    assert(r:size() == y:cols(), "incompatible cvector-cmatrix sizes")
    clib.mad_cmat_cmul(x.data, y.data, r.data, r:rows(), r:cols())
  else
    error("incompatible cvector (*) operands")
  end
  return r
end

function M.div (x, y, r_)
  if isnum(x) then -- num / cvec
    local r = r_ or cvector(y:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(y:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_divn (y.data, x, r.data, r:size())
    return r
  end

  -- iscvec(x)
  local r
  if isnum(y) then -- cvec / num => cvec * (1/num)
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_muln(x.data, 1/y, r.data, r:size())
  elseif iscpx(y) then -- cvec / cpx => cvec * (1/cpx)
    r, y = r_ or cvector(x:size()), 1/y
    assert(iscvec(r), "incompatible cvector kinds")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_mulc(x.data, y.re, y.im, r.data, r:size())
  elseif isvec(y) then -- cvec / vec
    r = r_ or cvector(x:size())
    assert(isvec(r), "incompatible cvector kinds")
    assert(x:size() == y:size(), "incompatible cvector sizes")
    assert(x:size() == r:size(), "incompatible cvector sizes")
    clib.mad_cvec_divv(x.data, y.data, r.data, r:size())
  elseif iscvec(y) then -- cvec / cvec
    r = r_ or cvector(x:size())
    assert(iscvec(r), "incompatible vector kinds")
    assert(x:size() == y:size(), "incompatible vector sizes")
    assert(x:size() == r:size(), "incompatible vector sizes")
    clib.mad_cvec_div(y.data, x.data, r.data, r:size())
  elseif ismat(y) then -- cvec / mat => cvec * inv(mat)
    error("vec/mat: NYI matrix inverse")
  elseif iscmat(y) then -- cvec / cmat => cvec * inv(cmat)
    error("vec/cmat: NYI matrix inverse")
  else
    error("incompatible cvector (/) operands")
  end
  return r
end

function M.tostring (x, sep)
  local n = x:size()
  local r = {}
  for i=1,n do r[i] = tostring(x:get(i)) end
  return table.concat(r, sep or ' ')
end

function M.totable(x, r_)
  local n = x:sizes()
  local r = r_ or tbl_new(n,0)
  assert(type(r) == 'table', "invalid argument, table expected")
  for i=1,n do r[i] = x:get(i) end
  return r
end

M.__unm      = M.unm
M.__add      = M.add
M.__sub      = M.sub
M.__mul      = M.mul
M.__div      = M.div
M.__mod      = M.mod
M.__pow      = M.pow
M.__tostring = M.tostring
M.__index  = M

ffi.metatype('cvector_t', M)

-- END -------------------------------------------------------------------------
return cvector

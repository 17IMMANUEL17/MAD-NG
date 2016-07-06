--[=[
 o-----------------------------------------------------------------------------o
 |
 | Gmath (pure Lua) regression tests
 |
 | Methodical Accelerator Design - Copyright CERN 2015+
 | Support: http://cern.ch/mad  - mad at cern.ch
 | Authors: L. Deniau, laurent.deniau at cern.ch
 | Contrib: A.Z. Teska, aleksandra.teska at cern.ch
 |
 o-----------------------------------------------------------------------------o
 | You can redistribute this file and/or modify it under the terms of the GNU
 | General Public License GPLv3 (or later), as published by the Free Software
 | Foundation. This file is distributed in the hope that it will be useful, but
 | WITHOUT ANY WARRANTY OF ANY KIND. See http://gnu.org/licenses for details.
 o-----------------------------------------------------------------------------o

  Purpose:
  - Provide regression test suites for the gmath module without extension.

 o-----------------------------------------------------------------------------o
]=]

-- expected from other modules ------------------------------------------------o

local
  abs, acos, asin, atan, ceil, cos, cosh, deg, exp, floor, log, log10, max,
  min, rad, sin, sinh, sqrt, tan, tanh,                   -- (generic functions)
  atan2, frexp, ldexp, modf, random, randomseed,       -- (functions wo generic)
  fmod, pow,                                         -- (operators as functions)
  huge, pi =                                                      -- (constants)
  math.abs,   math.acos,  math.asin,  math.atan, math.ceil,   math.cos, cosh,
  math.deg,   math.exp,   math.floor, math.log,  math.log10,  math.max,
  math.min,   math.rad,   math.sin,   math.sinh, math.sqrt,   math.tan, tanh,
  math.atan2, math.frexp, math.ldexp, math.modf, math.random, math.randomseed,
  math.fmod,  math.pow,
  math.huge,  math.pi

local function is_number(a) return type(a) == "number" end
local function first (a,b) return a end
local function second(a,b) return b end

local eps  = 2.2204460492503130e-16
local huge = 1.7976931348623158e+308
local tiny = 2.2250738585072012e-308

local inf  = 1/0
local Inf  = 1/0
local nan  = 0/0
local NaN  = 0/0
local pi   = pi
local Pi   = pi

-- generic unary functions
local function abs   (x) return is_number(x) and abs  (x)  or x:abs  () end
local function acos  (x) return is_number(x) and acos (x)  or x:acos () end
local function asin  (x) return is_number(x) and asin (x)  or x:asin () end
local function atan  (x) return is_number(x) and atan (x)  or x:atan () end
local function ceil  (x) return is_number(x) and ceil (x)  or x:ceil () end
local function cos   (x) return is_number(x) and cos  (x)  or x:cos  () end
local function cosh  (x) return is_number(x) and cosh (x)  or x:cosh () end
local function deg   (x) return is_number(x) and deg  (x)  or x:deg  () end
local function exp   (x) return is_number(x) and exp  (x)  or x:exp  () end
local function floor (x) return is_number(x) and floor(x)  or x:floor() end
local function log   (x) return is_number(x) and log  (x)  or x:log  () end
local function log10 (x) return is_number(x) and log10(x)  or x:log10() end
local function rad   (x) return is_number(x) and rad  (x)  or x:rad  () end
local function sin   (x) return is_number(x) and sin  (x)  or x:sin  () end
local function sinh  (x) return is_number(x) and sinh (x)  or x:sinh () end
local function sqrt  (x) return is_number(x) and sqrt (x)  or x:sqrt () end
local function tan   (x) return is_number(x) and tan  (x)  or x:tan  () end
local function tanh  (x) return is_number(x) and tanh (x)  or x:tanh () end

-- generic binary functions
local function angle (x,y) return is_number(x) and atan2(y,x) or x:angle(y) end

-- generic variadic functions
local function max(x,...) return is_number(x) and max(x,...) or x:max(...) end
local function min(x,...) return is_number(x) and min(x,...) or x:min(...) end

-- extra generic functions
local function sign (x) return is_number(x) and (x>=0 and 1 or x<0 and -1 or x)  or x:sign()end
local function step (x) return is_number(x) and (x>=0 and 1 or x<0 and  0 or x)  or x:step()end
local function sinc (x) return is_number(x) and (abs(x)<1e-10 and 1 or sin(x)/x) or x:sinc()end
local function frac (x) return is_number(x) and second(modf(x)) or x:frac()                 end
local function trunc(x) return is_number(x) and first (modf(x)) or x:trunc()                end
local function round(x) return is_number(x) and (x>0 and floor(x+0.5) or x<0 and ceil(x-0.5) or x) or x:round() end

-- operators
local function unm(x  ) return -x     end
local function add(x,y) return  x + y end
local function sub(x,y) return  x - y end
local function mul(x,y) return  x * y end
local function div(x,y) return  x / y end
local function mod(x,y) return  x % y end
local function pow(x,y) return  x ^ y end

-- logical
local function eq(x,y) return x == y end
local function ne(x,y) return x ~= y end
local function lt(x,y) return x <  y end
local function le(x,y) return x <= y end
local function gt(x,y) return x >  y end
local function ge(x,y) return x >= y end

-- complex generic functions
local function carg (x) return is_number(x) and (x>=0 and 0 or x<0 and pi or x) or x:carg() end
local function real (x) return is_number(x) and x                               or x:real() end
local function imag (x) return is_number(x) and 0                               or x:imag() end
local function conj (x) return is_number(x) and x                               or x:conj() end
local function norm (x) return is_number(x) and abs(x)                          or x:norm() end
local function rect (x) return is_number(x) and abs(x) or x:rect()  end
local function polar(x) return is_number(x) and abs(x) or x:polar() end -- TODO +M.carg(x)*1i

-- locals ---------------------------------------------------------------------o

local lu = require 'luaunit'
local assertFalse, assertTrue, assertEquals, assertNotEquals, assertAlmostEquals
      = lu.assertFalse, lu.assertTrue, lu.assertEquals, lu.assertNotEquals,
        lu.assertAlmostEquals

-- regression test suite ------------------------------------------------------o

TestLuaGmath = {}

local values = {
  num  = {0, tiny, 2^-64, 2^-63, 2^-53, eps, 2^-52, 2*eps, 2^-32, 2^-31, 1e-9,
          0.1-eps, 0.1, 0.1+eps, 0.5, 0.7-eps, 0.7, 0.7+eps, 1-eps, 1, 1+eps,
          1.1, 1.7, 2, 10, 1e2, 1e3, 1e6, 1e9, 2^31, 2^32, 2^52, 2^53,
          2^63, 2^64, huge, inf},
  rad  = {0, eps, 2*eps, pi/180, pi/90, pi/36, pi/18, pi/12, pi/6, pi/4, pi/3, pi/2,
          pi-pi/3, pi-pi/4, pi-pi/6, pi-pi/12, pi},
  rad2 = {0, eps, 2*eps, pi/180, pi/90, pi/36, pi/18, pi/12, pi/6, pi/4, pi/3, pi/2},

  deg  = {0, eps, 2*eps, 1, 2, 5, 10, 15, 30, 45, 60, 90,
          120, 135, 150, 165, 180},
  deg2 = {0, eps, 2*eps, 1, 2, 5, 10, 15, 30, 45, 60, 90},
}

-- keep the order of the import above

-- constant

function TestLuaGmath:testConstant()
  assertEquals(  pi , 3.1415926535897932385 )
  assertEquals(  pi , atan(1)*4 )

  assertEquals(  pi ,  Pi )
  assertEquals( -pi , -Pi )

  assertNotEquals(  tiny,  2.2250738585072011e-308 )
  assertEquals   (  tiny,  2.2250738585072012e-308 ) -- reference
  assertEquals   (  tiny,  2.2250738585072013e-308 )
  assertEquals   (  tiny,  2.2250738585072014e-308 )
  assertEquals   (  tiny,  2.2250738585072015e-308 )
  assertEquals   (  tiny,  2.2250738585072016e-308 )
  assertNotEquals(  tiny,  2.2250738585072017e-308 )

  assertNotEquals( -tiny, -2.2250738585072011e-308 )
  assertEquals   ( -tiny, -2.2250738585072012e-308 )
  assertEquals   ( -tiny, -2.2250738585072013e-308 )
  assertEquals   ( -tiny, -2.2250738585072014e-308 )
  assertEquals   ( -tiny, -2.2250738585072015e-308 )
  assertEquals   ( -tiny, -2.2250738585072016e-308 )
  assertNotEquals( -tiny, -2.2250738585072017e-308 )

  assertNotEquals(  huge,  1.7976931348623156e+308 )
  assertEquals   (  huge,  1.7976931348623157e+308 )
  assertEquals   (  huge,  1.7976931348623158e+308 ) -- reference
  assertNotEquals(  huge,  1.7976931348623159e+308 )

  assertNotEquals( -huge, -1.7976931348623156e+308 )
  assertEquals   ( -huge, -1.7976931348623157e+308 )
  assertEquals   ( -huge, -1.7976931348623158e+308 )
  assertNotEquals( -huge, -1.7976931348623159e+308 )

  assertNotEquals(  eps ,  2.2204460492503129e-16  )
  assertEquals   (  eps ,  2.2204460492503130e-16  ) -- reference
  assertEquals   (  eps ,  2.2204460492503131e-16  )
  assertEquals   (  eps ,  2.2204460492503132e-16  )
  assertEquals   (  eps ,  2.2204460492503133e-16  )
  assertNotEquals(  eps ,  2.2204460492503134e-16  )

  assertNotEquals( -eps , -2.2204460492503129e-16  )
  assertEquals   ( -eps , -2.2204460492503130e-16  )
  assertEquals   ( -eps , -2.2204460492503131e-16  )
  assertEquals   ( -eps , -2.2204460492503132e-16  )
  assertEquals   ( -eps , -2.2204460492503133e-16  )
  assertNotEquals( -eps , -2.2204460492503134e-16  )

  assertEquals   (  inf,  Inf )
  assertEquals   ( -inf, -Inf )

  assertNotEquals(  nan,  nan )
  assertNotEquals( -nan,  nan )
  assertNotEquals(  nan, -nan )
  assertNotEquals( -nan, -nan )

  assertNotEquals(  nan,  NaN )
  assertNotEquals( -nan,  NaN )
  assertNotEquals(  nan, -NaN )
  assertNotEquals( -nan, -NaN )

  assertFalse( is_nan( inf)  )
  assertFalse( is_nan( Inf)  )
  assertFalse( is_nan(-inf)  )
  assertFalse( is_nan(-Inf)  )
  assertTrue ( is_nan( nan)  )
  assertTrue ( is_nan( NaN)  )
  assertTrue ( is_nan(-nan)  )
  assertTrue ( is_nan(-NaN)  )
  assertFalse( is_nan('nan') )
  assertFalse( is_nan('NaN') )

  assertEquals( tostring( nan), 'nan' )
  assertEquals( tostring(-nan), 'nan' )
  assertEquals( tostring( NaN), 'nan' )
  assertEquals( tostring(-NaN), 'nan' )
end

-- generic functions

function TestLuaGmath:testAbs()
  for _,v in ipairs(values.num) do
    assertEquals(  abs( v),  v )
    assertEquals(  abs(-v),  v )
    assertEquals( -abs(-v), -v )
  end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/abs(- 0 ), inf ) -- check for +0
  assertEquals( 1/abs(  0 ), inf ) -- check for +0
  assertEquals(   abs(-inf), inf )
  assertEquals(   abs( inf), inf )

  assertEquals( tostring(abs(nan)), 'nan' )
end

function TestLuaGmath:testAcos()
  for _,v in ipairs(values.rad) do
    assertAlmostEquals( acos(v/pi)    - (pi-acos(-v/pi)) , 0,  2*eps )
    assertAlmostEquals( acos(v/pi)    - (pi/2-asin(v/pi)), 0,  2*eps )
    assertAlmostEquals( acos(cos( v)) - v                , 0, 10*eps ) -- 8@1deg
    assertAlmostEquals( acos(cos(-v)) - v                , 0, 10*eps ) -- 8@1deg
  end
  local r4, r6, r12 = sqrt(2)/2, sqrt(3)/2, sqrt(2)*(sqrt(3)+1)/4
  assertEquals      ( acos(-1  ) -    pi   , 0        )
  assertAlmostEquals( acos(-r12) - 11*pi/12, 0, 2*eps )
  assertAlmostEquals( acos(-r6 ) -  5*pi/6 , 0,   eps )
  assertAlmostEquals( acos(-r4 ) -  3*pi/4 , 0,   eps )
  assertAlmostEquals( acos(-0.5) -  2*pi/3 , 0, 2*eps )
  assertAlmostEquals( acos( 0  ) -    pi/2 , 0,   eps )
  assertAlmostEquals( acos( 0.5) -    pi/3 , 0,   eps )
  assertAlmostEquals( acos( r4 ) -    pi/4 , 0,   eps )
  assertAlmostEquals( acos( r6 ) -    pi/6 , 0,   eps )
  assertAlmostEquals( acos( r12) -    pi/12, 0,   eps )
  assertAlmostEquals( acos( r12) -    pi/12, 0,   eps )
  assertAlmostEquals( acos( r6 ) -    pi/6 , 0,   eps )
  assertAlmostEquals( acos( r4 ) -    pi/4 , 0,   eps )
  assertAlmostEquals( acos( 0.5) -    pi/3 , 0,   eps )
  assertAlmostEquals( acos( 0  ) -    pi/2 , 0,   eps )
  assertAlmostEquals( acos(-0.5) -  2*pi/3 , 0, 2*eps )
  assertAlmostEquals( acos(-r4 ) -  3*pi/4 , 0,   eps )
  assertAlmostEquals( acos(-r6 ) -  5*pi/6 , 0,   eps )
  assertAlmostEquals( acos(-r12) - 11*pi/12, 0, 2*eps )
  assertEquals      ( acos(-1  ) -    pi   , 0        )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(          acos( 1    ) ,   0   )
  assertEquals( tostring(acos(-1-eps)), 'nan' )
  assertEquals( tostring(acos( 1+eps)), 'nan' )
  assertEquals( tostring(acos(nan   )), 'nan' )
end

function TestLuaGmath:testAsin()
  for _,v in ipairs(values.rad2) do
    assertAlmostEquals( asin(v/pi)    - -asin(-v/pi)     , 0, eps )
    assertAlmostEquals( asin(v/pi)    - (pi/2-acos(v/pi)), 0, eps )
    assertAlmostEquals( asin(sin( v)) -  v               , 0, eps )
    assertAlmostEquals( asin(sin(-v)) - -v               , 0, eps )
  end
  local r3, r4, r12 = sqrt(3)/2, sqrt(2)/2, sqrt(2)*(sqrt(3)-1)/4
  assertEquals      ( asin( r12) -  pi/12, 0      )
  assertAlmostEquals( asin( 0.5) -  pi/6 , 0, eps )
  assertAlmostEquals( asin( r4 ) -  pi/4 , 0, eps )
  assertEquals      ( asin( r3 ) -  pi/3 , 0      )
  assertEquals      ( asin( 1  ) -  pi/2 , 0      )
  assertEquals      ( asin( r3 ) -  pi/3 , 0      )
  assertAlmostEquals( asin( r4 ) -  pi/4 , 0, eps )
  assertAlmostEquals( asin( 0.5) -  pi/6 , 0, eps )
  assertEquals      ( asin( r12) -  pi/12, 0      )
  assertEquals      ( asin(-r12) - -pi/12, 0      )
  assertAlmostEquals( asin(-0.5) - -pi/6 , 0, eps )
  assertAlmostEquals( asin(-r4 ) - -pi/4 , 0, eps )
  assertEquals      ( asin(-r3 ) - -pi/3 , 0      )
  assertEquals      ( asin(-1  ) - -pi/2 , 0      )
  assertEquals      ( asin(-r3 ) - -pi/3 , 0      )
  assertAlmostEquals( asin(-r4 ) - -pi/4 , 0, eps )
  assertAlmostEquals( asin(-0.5) - -pi/6 , 0, eps )
  assertEquals      ( asin(-r12) - -pi/12, 0      )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(        1/asin( 0    ) ,  inf  ) -- check for +0
  assertEquals(        1/asin(-0    ) , -inf  ) -- check for -0
  assertEquals( tostring(asin(-1-eps)), 'nan' )
  assertEquals( tostring(asin( 1+eps)), 'nan' )
  assertEquals( tostring(asin(nan   )), 'nan' )
end

function TestLuaGmath:testAtan()
  for _,v in ipairs(values.num) do
    assertAlmostEquals( atan(v) - -atan(-v), 0, eps) -- randomly not equal ±eps
  end
  for _,v in ipairs(values.rad2) do
    assertAlmostEquals( atan(tan( v)) -  v, 0, eps )
    assertAlmostEquals( atan(tan(-v)) - -v, 0, eps )
  end
  local r3, r6, r12 = sqrt(3), 1/sqrt(3), 2-sqrt(3)
  assertAlmostEquals( atan(-r3 ) - -pi/3 , 0, eps )
  assertEquals      ( atan(-1  ) - -pi/4 , 0      )
  assertAlmostEquals( atan(-r6 ) - -pi/6 , 0, eps )
  assertAlmostEquals( atan(-r12) - -pi/12, 0, eps )
  assertAlmostEquals( atan( r12) -  pi/12, 0, eps )
  assertAlmostEquals( atan( r6 ) -  pi/6 , 0, eps )
  assertEquals      ( atan( 1  ) -  pi/4 , 0      )
  assertAlmostEquals( atan( r3 ) -  pi/3 , 0, eps )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/atan( 0  ),  inf  ) -- check for -0
  assertEquals( 1/atan(-0  ), -inf  ) -- check for +0
  assertEquals(   atan(-inf), -pi/2 )
  assertEquals(   atan( inf),  pi/2 )
  assertEquals( tostring(atan(nan)), 'nan' )
end

function TestLuaGmath:testCeil()
  assertEquals( ceil( tiny) ,     1 )
  assertEquals( ceil(  0.1) ,     1 )
  assertEquals( ceil(  0.5) ,     1 )
  assertEquals( ceil(  0.7) ,     1 )
  assertEquals( ceil(    1) ,     1 )
  assertEquals( ceil(  1.1) ,     2 )
  assertEquals( ceil(  1.5) ,     2 )
  assertEquals( ceil(  1.7) ,     2 )
  assertEquals( ceil( huge) ,  huge )
  assertEquals( ceil(-tiny) , -   0 )
  assertEquals( ceil(- 0.1) , -   0 )
  assertEquals( ceil(- 0.5) , -   0 )
  assertEquals( ceil(- 0.7) , -   0 )
  assertEquals( ceil(-   1) , -   1 )
  assertEquals( ceil(- 1.1) , -   1 )
  assertEquals( ceil(- 1.5) , -   1 )
  assertEquals( ceil(- 1.7) , -   1 )
  assertEquals( ceil(-huge) , -huge )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/ceil(-  0 ) , -inf ) -- check for -0
  assertEquals( 1/ceil(   0 ) ,  inf ) -- check for +0
  assertEquals(   ceil(- inf) , -inf )
  assertEquals(   ceil(  inf) ,  inf )

  assertEquals( tostring(ceil(nan)), 'nan' )
end

function TestLuaGmath:testCos()
  for _,v in ipairs(values.rad) do
    assertAlmostEquals( cos(v)           - cos(-v)         , 0, eps )
    assertAlmostEquals( cos(v)           - sin(pi/2-v)     , 0, eps )
    assertAlmostEquals( cos(v)           - (1-2*sin(v/2)^2), 0, eps )
    assertAlmostEquals( cos(acos( v/pi)) -  v/pi           , 0, eps )
    assertAlmostEquals( cos(acos(-v/pi)) - -v/pi           , 0, eps )
  end
  local r4, r6, r12 = sqrt(2)/2, sqrt(3)/2, sqrt(2)*(sqrt(3)+1)/4
  assertEquals      ( cos(    pi   ) - -1  , 0      )
  assertAlmostEquals( cos( 11*pi/12) - -r12, 0, eps )
  assertAlmostEquals( cos(  5*pi/6 ) - -r6 , 0, eps )
  assertAlmostEquals( cos(  3*pi/4 ) - -r4 , 0, eps )
  assertAlmostEquals( cos(  2*pi/3 ) - -0.5, 0, eps )
  assertAlmostEquals( cos(    pi/2 ) -  0  , 0, eps )
  assertAlmostEquals( cos(    pi/3 ) -  0.5, 0, eps )
  assertAlmostEquals( cos(    pi/4 ) -  r4 , 0, eps )
  assertAlmostEquals( cos(    pi/6 ) -  r6 , 0, eps )
  assertAlmostEquals( cos(    pi/12) -  r12, 0, eps )
  assertAlmostEquals( cos(-   pi/12) -  r12, 0, eps )
  assertAlmostEquals( cos(-   pi/6 ) -  r6 , 0, eps )
  assertAlmostEquals( cos(-   pi/4 ) -  r4 , 0, eps )
  assertAlmostEquals( cos(-   pi/3 ) -  0.5, 0, eps )
  assertAlmostEquals( cos(-   pi/2 ) -  0  , 0, eps )
  assertAlmostEquals( cos(- 2*pi/3 ) - -0.5, 0, eps )
  assertAlmostEquals( cos(- 3*pi/4 ) - -r4 , 0, eps )
  assertAlmostEquals( cos(- 5*pi/6 ) - -r6 , 0, eps )
  assertAlmostEquals( cos(-11*pi/12) - -r12, 0, eps )
  assertEquals      ( cos(-   pi   ) - -1  , 0      )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(          cos( -0 ) ,   1   )
  assertEquals(          cos(  0 ) ,   1   )
  assertEquals( tostring(cos(-inf)), 'nan' )
  assertEquals( tostring(cos( inf)), 'nan' )
  assertEquals( tostring(cos( nan)), 'nan' )
end

function TestLuaGmath:testCosh()
  for _,v in ipairs(values.num) do
    assertEquals( cosh(v), cosh(-v) )
    if cosh(v) <= huge then
      assertAlmostEquals( cosh(v) / ((exp(v)+exp(-v))/2), 1,   eps )
      assertAlmostEquals( cosh(v) / ( 1 + 2*sinh(v/2)^2), 1,   eps )
      assertAlmostEquals( cosh(v) / (-1 + 2*cosh(v/2)^2), 1, 2*eps )
      assertAlmostEquals(  exp(v) / (cosh(v) + sinh(v)) , 1,   eps )
    end
  end
  assertEquals( cosh(-711), inf )
  assertEquals( cosh( 711), inf )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( cosh(-0  ), 1   )
  assertEquals( cosh( 0  ), 1   )
  assertEquals( cosh(-inf), inf )
  assertEquals( cosh( inf), inf )

  assertEquals( tostring(cosh(nan)), 'nan' )
end

function TestLuaGmath:testDeg()
  local r = 57.2957795130823208768 -- 180/pi
  for _,v in ipairs(values.rad) do
    assertEquals( deg( v) ,  v*r )
    assertEquals( deg(-v) , -v*r )
  end
  assertEquals      ( deg(-inf    )       , -inf      )
  assertEquals      ( deg(-2*pi   ) - -360, 0         )
  assertEquals      ( deg(-  pi   ) - -180, 0         )
  assertEquals      ( deg(-  pi/2 ) - - 90, 0         )
  assertAlmostEquals( deg(-  pi/3 ) - - 60, 0, 40*eps ) -- pb w ± ?
  assertEquals      ( deg(-  pi/4 ) - - 45, 0         )
  assertAlmostEquals( deg(-  pi/6 ) - - 30, 0, 40*eps ) -- pb w ± ?
  assertEquals      ( deg(-  pi/18) - - 10, 0         )
  assertEquals      ( deg(   0    ) -    0, 0         )
  assertEquals      ( deg(   pi/18) -   10, 0         )
  assertAlmostEquals( deg(   pi/6 ) -   30, 0, 40*eps ) -- pb w ± ?
  assertEquals      ( deg(   pi/4 ) -   45, 0         )
  assertAlmostEquals( deg(   pi/3 ) -   60, 0, 40*eps ) -- pb w ± ?
  assertEquals      ( deg(   pi/2 ) -   90, 0         )
  assertEquals      ( deg(   pi   ) -  180, 0         )
  assertEquals      ( deg( 2*pi   ) -  360, 0         )
  assertEquals      ( deg( inf    )       ,  inf      )

  assertAlmostEquals( deg(-  pi/3 ) / - 60, 1, eps )
  assertAlmostEquals( deg(-  pi/6 ) / - 30, 1, eps )
  assertAlmostEquals( deg(   pi/6 ) /   30, 1, eps )
  assertAlmostEquals( deg(   pi/3 ) /   60, 1, eps )

  assertEquals( tostring(deg(nan)), 'nan' )
end

function TestLuaGmath:testExp()
  -- SetPrecision[Table[Exp[x],{x, -1, 1, 0.1}],20]
  local val1 = {0.36787944117144233402, 0.40656965974059910973,
  0.44932896411722156316, 0.49658530379140952693, 0.54881163609402638937,
  0.60653065971263342426, 0.67032004603563932754, 0.74081822068171787610,
  0.81873075307798193201, 0.90483741803595962860, 1, 1.1051709180756477124,
  1.2214027581601698547, 1.3498588075760031835, 1.4918246976412703475,
  1.6487212707001281942, 1.8221188003905091080, 2.0137527074704766328,
  2.2255409284924678737, 2.4596031111569498506, 2.7182818284590450908}
  -- SetPrecision[Table[Exp[x],{x, -10, -1, 1}],20]
  local val2 = {0.00004539992976248485154, 0.0001234098040866795495,
  0.0003354626279025118388, 0.0009118819655545162080, 0.002478752176666358423,
  0.006737946999085467097, 0.018315638888734180294, 0.04978706836786394298,
  0.13533528323661269189, 0.36787944117144232160}
  -- SetPrecision[Table[Exp[x],{x, 1, 10, 1}],20]
  local val3 = {2.7182818284590452354, 7.389056098930650227,
  20.085536923187667741, 54.59815003314423908, 148.41315910257660342,
  403.4287934927351226, 1096.6331584284585993, 2980.957987041728275,
  8103.083927575384008, 22026.46579480671652}

  local i
  i=0 for v=-1,1,0.1 do i=i+1 -- should be done with ranges...
    v = -1+(i-1)*0.1
    assertAlmostEquals( exp(v) - val1[i], 0, 2*eps )
  end
  i=0 for v=-10,-1 do i=i+1
    assertAlmostEquals( exp(v) - val2[i], 0, eps )
  end
  i=0 for v=1,10 do i=i+1
    assertAlmostEquals( exp(v) - val3[i], 0, eps )
  end

  for i,v in ipairs(values.num) do
    if v > 1/709.78 and v < 709.78 then
      assertAlmostEquals( exp(v+1/v) / (exp(v)*exp(1/v)) - 1, 0, 25*eps )
      assertAlmostEquals( exp(log(v)) / v - 1, 0, 2*eps )
      assertAlmostEquals( log(exp(v)) / v - 1, 0, 4*eps )
    end
  end

  assertEquals      ( exp(-inf) , 0   )
  assertEquals      ( exp(-  1) , 0.36787944117144232159 )
  assertEquals      ( exp(-0.5) , 0.60653065971263342360 )
  assertAlmostEquals( exp(-0.1) - 0.90483741803595957316, 0, eps )
  assertEquals      ( exp(   0) , 1   )
  assertEquals      ( exp( 0.1) , 1.10517091807564762481 )
  assertEquals      ( exp( 0.5) , 1.64872127070012814684 )
  assertEquals      ( exp(   1) , 2.71828182845904523536 )
  assertEquals      ( exp( inf) , inf )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( exp(-0  ),  1  )
  assertEquals( exp( 0  ),  1  )
  assertEquals( exp(-inf),  0  )
  assertEquals( exp( inf), inf )

  assertEquals( tostring(exp(nan)), 'nan' )
end

function TestLuaGmath:testFloor()
  assertEquals( floor( tiny) ,     0 )
  assertEquals( floor(  0.1) ,     0 )
  assertEquals( floor(  0.5) ,     0 )
  assertEquals( floor(  0.7) ,     0 )
  assertEquals( floor(    1) ,     1 )
  assertEquals( floor(  1.1) ,     1 )
  assertEquals( floor(  1.5) ,     1 )
  assertEquals( floor(  1.7) ,     1 )
  assertEquals( floor( huge) ,  huge )
  assertEquals( floor(-tiny) , -   1 )
  assertEquals( floor(- 0.1) , -   1 )
  assertEquals( floor(- 0.5) , -   1 )
  assertEquals( floor(- 0.7) , -   1 )
  assertEquals( floor(-   1) , -   1 )
  assertEquals( floor(- 1.1) , -   2 )
  assertEquals( floor(- 1.5) , -   2 )
  assertEquals( floor(- 1.7) , -   2 )
  assertEquals( floor(-huge) , -huge )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/floor(-  0 ) , -inf ) -- check for -0
  assertEquals( 1/floor(   0 ) ,  inf ) -- check for +0
  assertEquals(   floor(- inf) , -inf )
  assertEquals(   floor(  inf) ,  inf )

  assertEquals( tostring(floor(nan)), 'nan' )
end

function TestLuaGmath:testLog()
  -- also used/tested in testExp
  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x > eps and y > eps  and x < 1/eps and y < 1/eps then
      assertAlmostEquals(log(x*y) - (log(x)+log(y)), 0, 40*eps)
    end
  end end
  for i=0,200 do
    assertAlmostEquals( log(2^ i) -  i*log(2), 0, 150*eps)
    assertAlmostEquals( log(2^-i) - -i*log(2), 0, 150*eps)
  end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( log(-0) , -inf )
  assertEquals( log( 0) , -inf )
  assertEquals( log(1)  ,  0   )
  assertEquals( log(inf),  inf )

  assertEquals( tostring(log(-tiny)), 'nan' )
  assertEquals( tostring(log(-inf )), 'nan' )
  assertEquals( tostring(log( nan )), 'nan' )
end

function TestLuaGmath:testLog10()
  for i,v in ipairs(values.num) do
    if v > 0 and v < inf then
      assertAlmostEquals( log10(v) - log(v)/log(10), 0, 300*eps)
    end
  end
  for i=0,200 do
    assertAlmostEquals( log10(10^ i) -  i, 0, 150*eps)
    assertAlmostEquals( log10(10^-i) - -i, 0, 150*eps)
  end
  assertEquals( log10( 10), 1   )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( log10(- 0),-inf )
  assertEquals( log10(  0),-inf )
  assertEquals( log10(  1),  0  )
  assertEquals( log10(inf), inf )

  assertEquals( tostring(log10(-tiny)), 'nan' )
  assertEquals( tostring(log10(-inf )), 'nan' )
  assertEquals( tostring(log10( nan )), 'nan' )
end

function TestLuaGmath:testMax()
  assertEquals( max(table.unpack(values.num )), inf  )
  assertEquals( max(table.unpack(values.rad )),  pi  )
  assertEquals( max(table.unpack(values.deg )), 180  )
  assertEquals( max(table.unpack(values.rad2)),  pi/2)
  assertEquals( max(table.unpack(values.deg2)),  90  )
  local t1, t2, t3, t4, t5 = {}, {}, {}, {}, {}
  for i,v in ipairs(values.num ) do t1[i] = -v end
  for i,v in ipairs(values.rad ) do t2[i] = -v end
  for i,v in ipairs(values.deg ) do t3[i] = -v end
  for i,v in ipairs(values.rad2) do t4[i] = -v end
  for i,v in ipairs(values.deg2) do t5[i] = -v end
  assertEquals( max(table.unpack(t1)), 0 )
  assertEquals( max(table.unpack(t2)), 0 )
  assertEquals( max(table.unpack(t3)), 0 )
  assertEquals( max(table.unpack(t4)), 0 )
  assertEquals( max(table.unpack(t5)), 0 )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( max(nan, -inf), -inf )
  assertEquals( max(nan,   0 ),   0  )
  assertEquals( max(nan,  inf),  inf )

  assertEquals( tostring(max(nan)), 'nan' )
end

function TestLuaGmath:testMin()
  assertEquals( min(table.unpack(values.num )), 0 )
  assertEquals( min(table.unpack(values.rad )), 0 )
  assertEquals( min(table.unpack(values.deg )), 0 )
  assertEquals( min(table.unpack(values.rad2)), 0 )
  assertEquals( min(table.unpack(values.deg2)), 0 )
  local t1, t2, t3, t4, t5 = {}, {}, {}, {}, {}
  for i,v in ipairs(values.num ) do t1[i] = -v end
  for i,v in ipairs(values.rad ) do t2[i] = -v end
  for i,v in ipairs(values.deg ) do t3[i] = -v end
  for i,v in ipairs(values.rad2) do t4[i] = -v end
  for i,v in ipairs(values.deg2) do t5[i] = -v end
  assertEquals( min(table.unpack(t1)), -inf  )
  assertEquals( min(table.unpack(t2)), - pi  )
  assertEquals( min(table.unpack(t3)), -180  )
  assertEquals( min(table.unpack(t4)), - pi/2)
  assertEquals( min(table.unpack(t5)), - 90  )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( min(nan, -inf), -inf )
  assertEquals( min(nan,   0 ),   0  )
  assertEquals( min(nan,  inf),  inf )

  assertEquals( tostring(min(nan)), 'nan' )
end

function TestLuaGmath:testModf()
  local s=function(n,f) return n+f end

  for _,v in ipairs(values.num) do
    if v == inf then break end
    assertEquals( s(modf( v+eps)),  v+eps )
    assertEquals( s(modf( v-eps)),  v-eps )
    assertEquals( s(modf(-v+eps)), -v+eps )
    assertEquals( s(modf(-v-eps)), -v-eps )
    assertEquals( s(modf( v+0.1)),  v+0.1 )
    assertEquals( s(modf( v-0.1)),  v-0.1 )
    assertEquals( s(modf(-v+0.1)), -v+0.1 )
    assertEquals( s(modf(-v-0.1)), -v-0.1 )
    assertEquals( s(modf( v+0.7)),  v+0.7 )
    assertEquals( s(modf( v-0.7)),  v-0.7 )
    assertEquals( s(modf(-v+0.7)), -v+0.7 )
    assertEquals( s(modf(-v-0.7)), -v-0.7 )
  end
  assertEquals( {modf(    0)} , {    0,     0} )
  assertEquals( {modf( tiny)} , {    0,  tiny} )
  assertEquals( {modf(  0.1)} , {    0,   0.1} )
  assertEquals( {modf(  0.5)} , {    0,   0.5} )
  assertEquals( {modf(  0.7)} , {    0,   0.7} )
  assertEquals( {modf(    1)} , {    1,     0} )
  assertEquals( {modf(  1.5)} , {    1,   0.5} )
  assertEquals( {modf(  1.7)} , {    1,   0.7} )
  assertEquals( {modf( huge)} , { huge,     0} )
  assertEquals( {modf(  inf)} , {  inf,     0} )
  assertEquals( {modf(-   0)} , {    0, -   0} )
  assertEquals( {modf(-tiny)} , {    0, -tiny} )
  assertEquals( {modf(- 0.1)} , {-   0, - 0.1} )
  assertEquals( {modf(- 0.5)} , {-   0, - 0.5} )
  assertEquals( {modf(- 0.7)} , {-   0, - 0.7} )
  assertEquals( {modf(-   1)} , {-   1, -   0} )
  assertEquals( {modf(- 1.5)} , {-   1, - 0.5} )
  assertEquals( {modf(- 1.7)} , {-   1, - 0.7} )
  assertEquals( {modf(-huge)} , {-huge, -   0} )
  assertEquals( {modf(- inf)} , {- inf, -   0} )

  local n,f
  n,f=modf( 1.1) assertEquals(n,  1) assertAlmostEquals( f-0.1, 0, eps/2 )
  n,f=modf(-1.1) assertEquals(n, -1) assertAlmostEquals( f+0.1, 0, eps/2 )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(    first(modf(-huge)), -huge )
  assertEquals(    first(modf( huge)),  huge )
  assertEquals( 1/second(modf(-huge)), -inf  ) -- check for -0
  assertEquals( 1/second(modf( huge)),  inf  ) -- check for +0
  assertEquals(    first(modf(-inf )), -inf  )
  assertEquals(    first(modf( inf )),  inf  )
  assertEquals( 1/second(modf(-inf )), -inf  ) -- check for -0
  assertEquals( 1/second(modf( inf )),  inf  ) -- check for +0

  assertEquals( tostring( first(modf(nan))), 'nan' )
  assertEquals( tostring(second(modf(nan))), 'nan' )
end

function TestLuaGmath:testPow()
  local pow = math.pow

  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x > 1/709.78 and y > 1/709.78 and x < 709.78 and y < 709.78 then
      assertAlmostEquals( log(pow(x,y)) - y*log(x), 0, max(abs(y*log(x)) * eps, eps) )
    end
  end end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals   (pow(  0 , - 11),  inf )
  assertEquals   (pow(- 0 , - 11), -inf )

  assertEquals   (pow(  0 , - .5),  inf )
  assertEquals   (pow(- 0 , - .5),  inf )
  assertEquals   (pow(  0 , -  2),  inf )
  assertEquals   (pow(- 0 , -  2),  inf )
  assertEquals   (pow(  0 , - 10),  inf )
  assertEquals   (pow(- 0 , - 10),  inf )

  assertEquals( 1/pow(  0 ,    1),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,    1), -inf ) -- check for -0
  assertEquals( 1/pow(  0 ,   11),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,   11), -inf ) -- check for -0

  assertEquals( 1/pow(  0 ,  0.5),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,  0.5),  inf ) -- check for +0
  assertEquals( 1/pow(  0 ,    2),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,    2),  inf ) -- check for +0
  assertEquals( 1/pow(  0 ,   10),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,   10),  inf ) -- check for +0
  assertEquals( 1/pow(  0 ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,  inf),  inf ) -- check for +0

  assertEquals   (pow(- 1 ,  inf),   1  )
  assertEquals   (pow(- 1 , -inf),   1  )

  assertEquals   (pow(  1 ,   0 ),   1  )
  assertEquals   (pow(  1 , - 0 ),   1  )
  assertEquals   (pow(  1 ,  0.5),   1  )
  assertEquals   (pow(  1 , -0.5),   1  )
  assertEquals   (pow(  1 ,   1 ),   1  )
  assertEquals   (pow(  1 , - 1 ),   1  )
  assertEquals   (pow(  1 ,  inf),   1  )
  assertEquals   (pow(  1 , -inf),   1  )
  assertEquals   (pow(  1 ,  nan),   1  )
  assertEquals   (pow(  1 , -nan),   1  )

  assertEquals   (pow(  0 ,   0 ),   1  )
  assertEquals   (pow(- 0 ,   0 ),   1  )
  assertEquals   (pow( 0.5,   0 ),   1  )
  assertEquals   (pow(-0.5,   0 ),   1  )
  assertEquals   (pow(  1 ,   0 ),   1  )
  assertEquals   (pow(- 1 ,   0 ),   1  )
  assertEquals   (pow( inf,   0 ),   1  )
  assertEquals   (pow(-inf,   0 ),   1  )
  assertEquals   (pow( nan,   0 ),   1  )
  assertEquals   (pow(-nan,   0 ),   1  )

  assertEquals   (pow(  0 , - 0 ),   1  )
  assertEquals   (pow(- 0 , - 0 ),   1  )
  assertEquals   (pow( 0.5, - 0 ),   1  )
  assertEquals   (pow(-0.5, - 0 ),   1  )
  assertEquals   (pow(  1 , - 0 ),   1  )
  assertEquals   (pow(- 1 , - 0 ),   1  )
  assertEquals   (pow( inf, - 0 ),   1  )
  assertEquals   (pow(-inf, - 0 ),   1  )
  assertEquals   (pow( nan, - 0 ),   1  )
  assertEquals   (pow(-nan, - 0 ),   1  )

  assertEquals   ( tostring(pow(- 1  , 0.5)), 'nan' )
  assertEquals   ( tostring(pow(- 1  ,-0.5)), 'nan' )
  assertEquals   ( tostring(pow(- 1  , 1.5)), 'nan' )
  assertEquals   ( tostring(pow(- 1  ,-1.5)), 'nan' )

  assertEquals   (pow(  0   , -inf),  inf )
  assertEquals   (pow(- 0   , -inf),  inf )
  assertEquals   (pow( 0.5  , -inf),  inf )
  assertEquals   (pow(-0.5  , -inf),  inf )
  assertEquals   (pow( 1-eps, -inf),  inf )
  assertEquals   (pow(-1+eps, -inf),  inf )

  assertEquals( 1/pow( 1+eps, -inf),  inf ) -- check for +0
  assertEquals( 1/pow(-1-eps, -inf),  inf ) -- check for +0
  assertEquals( 1/pow( 1.5  , -inf),  inf ) -- check for +0
  assertEquals( 1/pow(-1.5  , -inf),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , -inf),  inf ) -- check for +0
  assertEquals( 1/pow(-inf  , -inf),  inf ) -- check for +0

  assertEquals( 1/pow(  0   ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(- 0   ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow( 0.5  ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(-0.5  ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow( 1-eps,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(-1+eps,  inf),  inf ) -- check for +0

  assertEquals   (pow( 1+eps,  inf),  inf )
  assertEquals   (pow(-1-eps,  inf),  inf )
  assertEquals   (pow( 1.5  ,  inf),  inf )
  assertEquals   (pow(-1.5  ,  inf),  inf )
  assertEquals   (pow( inf  ,  inf),  inf )
  assertEquals   (pow(-inf  ,  inf),  inf )

  assertEquals( 1/pow(-inf  , -  1), -inf ) -- check for -0
  assertEquals( 1/pow(-inf  , - 11), -inf ) -- check for -0
  assertEquals( 1/pow(-inf  , -0.5),  inf ) -- check for +0
  assertEquals( 1/pow(-inf  , -  2),  inf ) -- check for +0
  assertEquals( 1/pow(-inf  , - 10),  inf ) -- check for +0

  assertEquals  ( pow(-inf  ,    1), -inf )
  assertEquals  ( pow(-inf  ,   11), -inf )
  assertEquals  ( pow(-inf  ,  0.5),  inf )
  assertEquals  ( pow(-inf  ,    2),  inf )
  assertEquals  ( pow(-inf  ,   10),  inf )

  assertEquals( 1/pow( inf  , -0.5),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , -  1),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , -  2),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , - 10),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , - 11),  inf ) -- check for +0

  assertEquals  ( pow( inf  ,  0.5),  inf )
  assertEquals  ( pow( inf  ,    1),  inf )
  assertEquals  ( pow( inf  ,    2),  inf )
  assertEquals  ( pow( inf  ,   10),  inf )
  assertEquals  ( pow( inf  ,   11),  inf )

  assertEquals   ( tostring(pow( 0  ,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-0  ,  nan)), 'nan' )
  assertEquals   ( tostring(pow( 0  , -nan)), 'nan' )
  assertEquals   ( tostring(pow(-0  , -nan)), 'nan' )

  assertEquals   ( tostring(pow(-1  ,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-1  , -nan)), 'nan' )
  assertEquals   ( tostring(pow( nan,   1 )), 'nan' )
  assertEquals   ( tostring(pow(-nan,   1 )), 'nan' )
  assertEquals   ( tostring(pow( nan, - 1 )), 'nan' )
  assertEquals   ( tostring(pow(-nan, - 1 )), 'nan' )

  assertEquals   ( tostring(pow( inf,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-inf,  nan)), 'nan' )
  assertEquals   ( tostring(pow( inf, -nan)), 'nan' )
  assertEquals   ( tostring(pow(-inf, -nan)), 'nan' )
  assertEquals   ( tostring(pow( nan,  inf)), 'nan' )
  assertEquals   ( tostring(pow(-nan,  inf)), 'nan' )
  assertEquals   ( tostring(pow( nan, -inf)), 'nan' )
  assertEquals   ( tostring(pow(-nan, -inf)), 'nan' )

  assertEquals   ( tostring(pow( nan,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-nan,  nan)), 'nan' )
  assertEquals   ( tostring(pow( nan, -nan)), 'nan' )
  assertEquals   ( tostring(pow(-nan, -nan)), 'nan' )
end

function TestLuaGmath:testRad()
  local r = 0.0174532925199432958 -- pi/180
  for _,v in ipairs(values.deg) do
    assertEquals( rad( v) ,  v*r )
    assertEquals( rad(-v) , -v*r )
  end
  assertEquals( rad(-inf), -inf   )
  assertEquals( rad(-360), -2*pi  )
  assertEquals( rad(-180), -pi    )
  assertEquals( rad(- 90), -pi/2  )
  assertEquals( rad(- 60), -pi/3  )
  assertEquals( rad(- 45), -pi/4  )
  assertEquals( rad(- 30), -pi/6  )
  assertEquals( rad(- 10), -pi/18 )
  assertEquals( rad(   0),  0     )
  assertEquals( rad(  10),  pi/18 )
  assertEquals( rad(  30),  pi/6  )
  assertEquals( rad(  45),  pi/4  )
  assertEquals( rad(  60),  pi/3  )
  assertEquals( rad(  90),  pi/2  )
  assertEquals( rad( 180),  pi    )
  assertEquals( rad( 360),  2*pi  )
  assertEquals( rad( inf),  inf   )

  assertEquals( tostring(rad(nan)), 'nan' )
end

function TestLuaGmath:testSin()
  for _,v in ipairs(values.rad) do
    assertAlmostEquals( sin(v)           - -sin(-v)             , 0, eps )
    assertAlmostEquals( sin(v)           -  cos(pi/2-v)         , 0, eps )
    assertAlmostEquals( sin(v)           - (2*sin(v/2)*cos(v/2)), 0, eps )
    assertAlmostEquals( sin(asin( v/pi)) -  v/pi                , 0, eps )
    assertAlmostEquals( sin(asin(-v/pi)) - -v/pi                , 0, eps )
  end
  local r3, r4, r12 = sqrt(3)/2, sqrt(2)/2, sqrt(2)*(sqrt(3)-1)/4
  assertAlmostEquals( sin(    pi   ) -  0  , 0,   eps )
  assertAlmostEquals( sin( 11*pi/12) -  r12, 0, 2*eps )
  assertAlmostEquals( sin(  5*pi/6 ) -  0.5, 0,   eps )
  assertAlmostEquals( sin(  3*pi/4 ) -  r4 , 0,   eps )
  assertAlmostEquals( sin(  2*pi/3 ) -  r3 , 0,   eps )
  assertAlmostEquals( sin(    pi/2 ) -  1  , 0,   eps )
  assertAlmostEquals( sin(    pi/3 ) -  r3 , 0,   eps )
  assertAlmostEquals( sin(    pi/4 ) -  r4 , 0,   eps )
  assertAlmostEquals( sin(    pi/6 ) -  0.5, 0,   eps )
  assertAlmostEquals( sin(    pi/12) -  r12, 0,   eps )
  assertEquals      ( sin(    0    ) -  0  , 0        )
  assertAlmostEquals( sin(-   pi/12) - -r12, 0,   eps )
  assertAlmostEquals( sin(-   pi/6 ) - -0.5, 0,   eps )
  assertAlmostEquals( sin(-   pi/4 ) - -r4 , 0,   eps )
  assertAlmostEquals( sin(-   pi/3 ) - -r3 , 0,   eps )
  assertAlmostEquals( sin(-   pi/2 ) - -1  , 0,   eps )
  assertAlmostEquals( sin(- 2*pi/3 ) - -r3 , 0,   eps )
  assertAlmostEquals( sin(- 3*pi/4 ) - -r4 , 0,   eps )
  assertAlmostEquals( sin(- 5*pi/6 ) - -0.5, 0,   eps )
  assertAlmostEquals( sin(-11*pi/12) - -r12, 0, 2*eps )
  assertAlmostEquals( sin(-   pi   ) - -0  , 0,   eps )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(        1/sin( -0 ) , -inf  ) -- check for -0
  assertEquals(        1/sin(  0 ) ,  inf  ) -- check for +0
  assertEquals( tostring(sin(-inf)), 'nan' )
  assertEquals( tostring(sin( inf)), 'nan' )
  assertEquals( tostring(sin( nan)), 'nan' )
end

function TestLuaGmath:testSinh()
  for _,v in ipairs(values.num) do
    assertEquals( sinh(v), -sinh(-v) )
    if v < 3e-8 then
      assertEquals( sinh(v), v )
    end
    if v > 19.0006 then
      assertEquals( sinh(v), cosh(v) )
    end
    if v < 1e-5 then
      assertAlmostEquals( sinh(v) - v , 0, eps )
    end
    if v > 1e-5 and v < 19.0006 then
      assertAlmostEquals( sinh(v) / (2*sinh(v/2)*cosh(v/2))  - 1, 0,   eps )
      assertAlmostEquals( sinh(v) / (exp(-v)*(exp(2*v)-1)/2) - 1, 0, 2*eps )
      assertAlmostEquals(  exp(v) / (cosh(v) + sinh(v))      - 1, 0,   eps )
    end
  end
  assertEquals( sinh(-711), -inf )
  assertEquals( sinh( 711),  inf )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/sinh(-0  ), -inf ) -- check for -0
  assertEquals( 1/sinh( 0  ),  inf ) -- check for +0
  assertEquals(   sinh(-inf), -inf )
  assertEquals(   sinh( inf),  inf )

  assertEquals( tostring(sinh(nan)), 'nan' )
end

function TestLuaGmath:testSqrt()
  for _,v in ipairs(values.num) do
    if v > 0 and v < inf then
      assertAlmostEquals( sqrt(v)*sqrt(v) / v - 1, 0, eps )
    end
  end
  assertEquals( tostring(sqrt(-inf)), 'nan' )
  assertEquals( tostring(sqrt(-1  )), 'nan' )
  assertEquals( tostring(sqrt(-0.1)), 'nan' )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/sqrt(- 0  ) , -inf ) -- check for -0
  assertEquals( 1/sqrt(  0  ) ,  inf ) -- check for +0
  assertEquals(   sqrt( inf ) ,  inf )
  assertEquals( tostring(sqrt(-tiny)), 'nan' )
  assertEquals( tostring(sqrt(-inf )), 'nan' )
  assertEquals( tostring(sqrt( nan )), 'nan' )
end

function TestLuaGmath:testTan()
  for _,v in ipairs(values.rad) do
    assertEquals      (tan( v) - -tan(-v)        , 0     )
    assertAlmostEquals(tan( v) -  sin( v)/cos( v), 0, eps)
    assertAlmostEquals(tan(-v) -  sin(-v)/cos(-v), 0, eps)
  end
  local r3, r6, r12 = sqrt(3), 1/sqrt(3), 2-sqrt(3)
  assertAlmostEquals(  tan(-pi )            , 0,   eps )
  assertAlmostEquals(  tan(-pi+pi/12) -  r12, 0,   eps )
  assertAlmostEquals(  tan(-pi+pi/6 ) -  r6 , 0,   eps )
  assertAlmostEquals(  tan(-pi+pi/4 ) -  1  , 0,   eps )
  assertAlmostEquals(  tan(-pi+pi/3 ) -  r3 , 0, 3*eps )
  assertAlmostEquals(1/tan(-pi/2    )       , 0,   eps )
  assertAlmostEquals(  tan(-pi/3    ) - -r3 , 0, 2*eps )
  assertAlmostEquals(  tan(-pi/4    ) - -1  , 0,   eps )
  assertAlmostEquals(  tan(-pi/6    ) - -r6 , 0,   eps )
  assertAlmostEquals(  tan(-pi/12   ) - -r12, 0,   eps )
  assertEquals      (  tan( 0       ) -  0  , 0        )
  assertAlmostEquals(  tan( pi/12   ) -  r12, 0,   eps )
  assertAlmostEquals(  tan( pi/6    ) -  r6 , 0,   eps )
  assertAlmostEquals(  tan( pi/4    ) -  1  , 0,   eps )
  assertAlmostEquals(  tan( pi/3    ) -  r3 , 0, 2*eps )
  assertAlmostEquals(1/tan( pi/2    )       , 0,   eps )
  assertAlmostEquals(  tan( pi-pi/3 ) - -r3 , 0, 3*eps )
  assertAlmostEquals(  tan( pi-pi/4 ) - -1  , 0,   eps )
  assertAlmostEquals(  tan( pi-pi/6 ) - -r6 , 0,   eps )
  assertAlmostEquals(  tan( pi-pi/12) - -r12, 0,   eps )
  assertAlmostEquals(  tan( pi )            , 0,   eps )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(        1/tan( -0 ) , -inf  ) -- check for -0
  assertEquals(        1/tan(  0 ) ,  inf  ) -- check for +0
  assertEquals( tostring(tan(-inf)), 'nan' )
  assertEquals( tostring(tan( inf)), 'nan' )
  assertEquals( tostring(tan( nan)), 'nan' )
end

function TestLuaGmath:testTanh()
  for _,v in ipairs(values.num) do
    assertEquals( tanh(v), -tanh(-v) )
    if v < 2e-8 then
      assertEquals( tanh(v), v )
    end
    if v > 19.06155 then
      assertEquals( tanh(v), 1 )
    end
    if v < 8.74e-06 then
      assertAlmostEquals( tanh(v) - v , 0, eps )
    end
    if v > 8.74e-06 and v < 19.06155 then
      assertAlmostEquals( tanh( v) -  sinh( v)/cosh( v), 0, eps )
      assertAlmostEquals( tanh(-v) -  sinh(-v)/cosh(-v), 0, eps )
    end
  end
  assertEquals( tanh(-inf     ), -1 )
  assertEquals( tanh(-19.06155), -1 )
  assertEquals( tanh(  0      ),  0 )
  assertEquals( tanh( 19.06155),  1 )
  assertEquals( tanh( inf)     ,  1 )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/tanh(-0  ), -inf ) -- check for -0
  assertEquals( 1/tanh( 0  ),  inf ) -- check for +0
  assertEquals(   tanh(-inf), -1   )
  assertEquals(   tanh( inf),  1   )
  assertEquals( tostring(tanh(nan)), 'nan' )
end

-- functions wo generic

function TestLuaGmath:testAtan2()
  for _,v in ipairs(values.rad2) do
    local x, y = cos(v), sin(v)
    assertAlmostEquals( atan2(y,x) - (pi/2-atan2( x,  y)), 0,   eps )
    assertAlmostEquals( atan2(y,x) - (pi  -atan2( y, -x)), 0, 2*eps )
    assertAlmostEquals( atan2(y,x) -      -atan2(-y,  x) , 0,   eps )
    assertAlmostEquals( atan2(y,x) - (pi  +atan2(-y, -x)), 0, 2*eps )
    if v > 0 then
      assertAlmostEquals( atan2(y,x) / atan (y/x), 1, eps )
    end
  end

  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x > 0 or y > 0 then
    assertAlmostEquals( atan2(y,x) - (pi/2-atan2( x,  y)), 0, 2*eps )
    end
    assertAlmostEquals( atan2(y,x) - (pi  -atan2( y, -x)), 0, 2*eps )
    assertAlmostEquals( atan2(y,x) -      -atan2(-y,  x) , 0,   eps )
    assertAlmostEquals( atan2(y,x) - (pi  +atan2(-y, -x)), 0, 2*eps )
  end end

  assertEquals( atan2(    1,    0),  pi/2   )
  assertEquals( atan2( -  1,    0), -pi/2   )
  assertEquals( atan2(  inf,    0),  pi/2   )
  assertEquals( atan2( -inf,    0), -pi/2   )
  assertEquals( atan2(    0,    1),  0      )
  assertEquals( atan2(    1,    1),  pi/4   )
  assertEquals( atan2( -  1,    1), -pi/4   )
  assertEquals( atan2(  inf,    1),  pi/2   )
  assertEquals( atan2( -inf,    1), -pi/2   )
  assertEquals( atan2(    0, -  1),  pi     )
  assertEquals( atan2(    1, -  1),  pi/4*3 )
  assertEquals( atan2( -  1, -  1), -pi/4*3 )
  assertEquals( atan2(  inf, -  1),  pi/2   )
  assertEquals( atan2( -inf, -  1), -pi/2   )
  assertEquals( atan2(    0,  inf),  0      )
  assertEquals( atan2(    1,  inf),  0      )
  assertEquals( atan2( -  1,  inf),  0      )
  assertEquals( atan2(    0, -inf),  pi     )
  assertEquals( atan2(    1, -inf),  pi     )
  assertEquals( atan2( -  1, -inf), -pi     )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(  atan2(-0 ,-0   ) , -pi   )
  assertEquals(  atan2( 0 ,-0   ) ,  pi   )
  assertEquals(1/atan2(-0 , 0   ) , -inf  ) -- check for -0
  assertEquals(1/atan2( 0 , 0   ) ,  inf  ) -- check for +0
  assertEquals(  atan2(-0 ,-tiny) , -pi   )
  assertEquals(  atan2( 0 ,-tiny) ,  pi   )
  assertEquals(  atan2(-0 ,-1   ) , -pi   )
  assertEquals(  atan2( 0 ,-1   ) ,  pi   )
  assertEquals(  atan2(-0 ,-huge) , -pi   )
  assertEquals(  atan2( 0 ,-huge) ,  pi   )
  assertEquals(1/atan2(-0 , tiny) , -inf  ) -- check for -0
  assertEquals(1/atan2( 0 , tiny) ,  inf  ) -- check for +0
  assertEquals(1/atan2(-0 , 1   ) , -inf  ) -- check for -0
  assertEquals(1/atan2( 0 , 1   ) ,  inf  ) -- check for +0
  assertEquals(1/atan2(-0 , huge) , -inf  ) -- check for -0
  assertEquals(1/atan2( 0 , huge) ,  inf  ) -- check for +0
  assertEquals(  atan2(-tiny, -0) , -pi/2 )
  assertEquals(  atan2(-tiny,  0) , -pi/2 )
  assertEquals(  atan2(-1   , -0) , -pi/2 )
  assertEquals(  atan2(-1   ,  0) , -pi/2 )
  assertEquals(  atan2(-huge, -0) , -pi/2 )
  assertEquals(  atan2(-huge,  0) , -pi/2 )
  assertEquals(  atan2( tiny, -0) ,  pi/2 )
  assertEquals(  atan2( tiny,  0) ,  pi/2 )
  assertEquals(  atan2( 1   , -0) ,  pi/2 )
  assertEquals(  atan2( 1   ,  0) ,  pi/2 )
  assertEquals(  atan2( huge, -0) ,  pi/2 )
  assertEquals(  atan2( huge,  0) ,  pi/2 )

  assertEquals(  atan2(-tiny, -inf) , -pi )
  assertEquals(  atan2(-1   , -inf) , -pi )
  assertEquals(  atan2(-huge, -inf) , -pi )
  assertEquals(  atan2( tiny, -inf) ,  pi )
  assertEquals(  atan2( 1   , -inf) ,  pi )
  assertEquals(  atan2( huge, -inf) ,  pi )
  assertEquals(1/atan2(-tiny,  inf) , -inf ) -- check for -0
  assertEquals(1/atan2(-1   ,  inf) , -inf ) -- check for +0
  assertEquals(1/atan2(-huge,  inf) , -inf ) -- check for -0
  assertEquals(1/atan2( tiny,  inf) ,  inf ) -- check for +0
  assertEquals(1/atan2( 1   ,  inf) ,  inf ) -- check for -0
  assertEquals(1/atan2( huge,  inf) ,  inf ) -- check for +0
  assertEquals(  atan2(-inf, -0   ) , -pi/2 )
  assertEquals(  atan2(-inf, -tiny) , -pi/2 )
  assertEquals(  atan2(-inf, -1   ) , -pi/2 )
  assertEquals(  atan2(-inf, -huge) , -pi/2 )
  assertEquals(  atan2(-inf,  0   ) , -pi/2 )
  assertEquals(  atan2(-inf,  tiny) , -pi/2 )
  assertEquals(  atan2(-inf,  1   ) , -pi/2 )
  assertEquals(  atan2(-inf,  huge) , -pi/2 )
  assertEquals(  atan2( inf, -0   ) ,  pi/2 )
  assertEquals(  atan2( inf, -tiny) ,  pi/2 )
  assertEquals(  atan2( inf, -1   ) ,  pi/2 )
  assertEquals(  atan2( inf, -huge) ,  pi/2 )
  assertEquals(  atan2( inf,  0   ) ,  pi/2 )
  assertEquals(  atan2( inf,  tiny) ,  pi/2 )
  assertEquals(  atan2( inf,  1   ) ,  pi/2 )
  assertEquals(  atan2( inf,  huge) ,  pi/2 )
  assertEquals(  atan2( inf,  -inf) , 3*pi/4 )
  assertEquals(  atan2(-inf,  -inf) ,-3*pi/4 )
  assertEquals(  atan2( inf,   inf) ,   pi/4 )
  assertEquals(  atan2(-inf,   inf) ,-  pi/4 )

  assertEquals( tostring(atan2(nan, 0 )), 'nan' )
  assertEquals( tostring(atan2( 0 ,nan)), 'nan' )
  assertEquals( tostring(atan2(nan,nan)), 'nan' )
end

function TestLuaGmath:testFMod()
  local e, n, f, r
  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x < y then
      assertEquals( fmod( x, y),  x )
      assertEquals( fmod(-x, y), -x )
      assertEquals( fmod( x,-y),  x )
      assertEquals( fmod(-x,-y), -x )
    elseif y/x >= tiny/eps and x < inf and y < inf then
      n = floor(x/y)
      f = fmod(x,y)
      r = x - (n*y + f)
      if r < 0 then r = r+y end
      e = n * eps / 10
      assertTrue( 0 <= f and f < y )
      assertTrue( r < e )
    end
  end end

  assertAlmostEquals( fmod(-5.1, -3  ) - -2.1, 0, 2*eps)
  assertAlmostEquals( fmod(-5.1,  3  ) - -2.1, 0, 2*eps)
  assertAlmostEquals( fmod( 5.1, -3  ) -  2.1, 0, 2*eps)
  assertAlmostEquals( fmod( 5.1,  3  ) -  2.1, 0, 2*eps)

  assertAlmostEquals( fmod(-5.1, -3.1) - -2  , 0, 2*eps)
  assertAlmostEquals( fmod(-5.1,  3.1) - -2  , 0, 2*eps)
  assertAlmostEquals( fmod( 5.1, -3.1) -  2  , 0, 2*eps)
  assertAlmostEquals( fmod( 5.1,  3.1) -  2  , 0, 2*eps)

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/fmod(- 0,  0.5), -inf) -- check for -0
  assertEquals( 1/fmod(  0,  0.5),  inf) -- check for +0
  assertEquals( 1/fmod(- 0, -0.5), -inf) -- check for -0
  assertEquals( 1/fmod(  0, -0.5),  inf) -- check for +0
  assertEquals( 1/fmod(- 0,  1  ), -inf) -- check for -0
  assertEquals( 1/fmod(  0,  1  ),  inf) -- check for +0
  assertEquals( 1/fmod(- 0, -1  ), -inf) -- check for -0
  assertEquals( 1/fmod(  0, -1  ),  inf) -- check for +0
  assertEquals( 1/fmod(- 0,  10 ), -inf) -- check for -0
  assertEquals( 1/fmod(  0,  10 ),  inf) -- check for +0
  assertEquals( 1/fmod(- 0, -10 ), -inf) -- check for -0
  assertEquals( 1/fmod(  0, -10 ),  inf) -- check for +0

  assertEquals(  fmod( 0.5,  inf),  0.5)
  assertEquals(  fmod(-0.5,  inf), -0.5)
  assertEquals(  fmod( 0.5, -inf),  0.5)
  assertEquals(  fmod(-0.5, -inf), -0.5)
  assertEquals(  fmod( 1  ,  inf),  1  )
  assertEquals(  fmod(-1  ,  inf), -1  )
  assertEquals(  fmod( 1  , -inf),  1  )
  assertEquals(  fmod(-1  , -inf), -1  )
  assertEquals(  fmod( 10 ,  inf),  10 )
  assertEquals(  fmod(-10 ,  inf), -10 )
  assertEquals(  fmod( 10 , -inf),  10 )
  assertEquals(  fmod(-10 , -inf), -10 )

  assertEquals( tostring(fmod( inf,  0.5)), 'nan' )
  assertEquals( tostring(fmod( inf, -0.5)), 'nan' )
  assertEquals( tostring(fmod(-inf,  0.5)), 'nan' )
  assertEquals( tostring(fmod(-inf, -0.5)), 'nan' )
  assertEquals( tostring(fmod( inf,  1  )), 'nan' )
  assertEquals( tostring(fmod( inf, -1  )), 'nan' )
  assertEquals( tostring(fmod(-inf,  1  )), 'nan' )
  assertEquals( tostring(fmod(-inf, -1  )), 'nan' )
  assertEquals( tostring(fmod( inf,  10 )), 'nan' )
  assertEquals( tostring(fmod( inf, -10 )), 'nan' )
  assertEquals( tostring(fmod(-inf,  10 )), 'nan' )
  assertEquals( tostring(fmod(-inf, -10 )), 'nan' )

  assertEquals( tostring(fmod( 0.5,  0  )), 'nan' )
  assertEquals( tostring(fmod(-0.5,  0  )), 'nan' )
  assertEquals( tostring(fmod( 0.5, -0  )), 'nan' )
  assertEquals( tostring(fmod(-0.5, -0  )), 'nan' )
  assertEquals( tostring(fmod( 1  ,  0  )), 'nan' )
  assertEquals( tostring(fmod(-1  ,  0  )), 'nan' )
  assertEquals( tostring(fmod( 1  , -0  )), 'nan' )
  assertEquals( tostring(fmod(-1  , -0  )), 'nan' )
  assertEquals( tostring(fmod( 10 ,  0  )), 'nan' )
  assertEquals( tostring(fmod(-10 ,  0  )), 'nan' )
  assertEquals( tostring(fmod( 10 , -0  )), 'nan' )
  assertEquals( tostring(fmod(-10 , -0  )), 'nan' )

  assertEquals( tostring(fmod( inf,  inf)), 'nan' )
  assertEquals( tostring(fmod(-inf,  inf)), 'nan' )
  assertEquals( tostring(fmod( inf, -inf)), 'nan' )
  assertEquals( tostring(fmod(-inf, -inf)), 'nan' )

  assertEquals( tostring(fmod( nan,  nan)), 'nan' )
  assertEquals( tostring(fmod(-nan,  nan)), 'nan' )
  assertEquals( tostring(fmod( nan, -nan)), 'nan' )
  assertEquals( tostring(fmod(-nan, -nan)), 'nan' )
end

function TestLuaGmath:testLdexp()
  for i,v in ipairs(values.num) do
    assertEquals( ldexp(v,  i), v*2^ i )
    assertEquals( ldexp(v, -i), v*2^-i )
    assertEquals( ldexp(v,  0), v )
    assertEquals( ldexp(0,  i), 0 )
  end
  for i,v in ipairs(values.rad) do
    assertEquals( ldexp(v,  i), v*2^ i )
    assertEquals( ldexp(v, -i), v*2^-i )
    assertEquals( ldexp(v,  0), v )
    assertEquals( ldexp(0,  i), 0 )
  end

  assertEquals( ldexp(-inf,   0), -inf )
  assertEquals( ldexp( 3  , 1.9),    6 )
  assertEquals( ldexp( 3  , 2.1),   12 )
  assertEquals( ldexp( inf,   0),  inf )

  assertEquals( tostring(ldexp(nan,   0)), 'nan' )
  assertEquals( tostring(ldexp(nan,   1)), 'nan' )
  assertEquals( tostring(ldexp(nan, nan)), 'nan' )
end

function TestLuaGmath:testFrexp()
  assertEquals( {frexp(0)}, {0,0} )
  assertEquals( {frexp(1)}, {0.5,1} )

  for i=-100,100 do
    assertEquals( ldexp(frexp(2^i)), 2^i )
  end
  for x=-100,100,0.1 do
    assertEquals( ldexp(frexp(x)), x )
  end

  assertEquals( {frexp(- inf)}, {-inf  ,     0} )
  assertEquals( {frexp(- 0.2)}, {-0.8  , -   2} )
  assertEquals( {frexp( tiny)}, { 0.5  , -1021} )
  assertEquals( {frexp(  eps)}, { 0.5  , -  51} )
  assertEquals( {frexp(  0.1)}, { 0.8  , -   3} )
  assertEquals( {frexp(  0.7)}, { 0.7  ,     0} )
  assertEquals( {frexp(  1  )}, { 0.5  ,     1} )
  assertEquals( {frexp(  1.1)}, { 0.55 ,     1} )
  assertEquals( {frexp(  1.7)}, { 0.85  ,    1} )
  assertEquals( {frexp(  2.1)}, { 0.525,     2} )
  assertEquals( {frexp(  inf)}, { inf  ,     0} )

  local f,e
  f,e = frexp(1-eps)
  assertEquals( 1 , 1 )
  assertEquals( 0 , 0 )
  f,e = frexp(1+eps)
  assertEquals( 1 , 1 )
  assertEquals( 0 , 0 )
  f,e = frexp(huge)
  assertAlmostEquals( f - 1    , 0, eps)
  assertEquals      ( e - 1024 , 0     )

  assertEquals( tostring(frexp(nan,   0)), 'nan' )
  assertEquals( tostring(frexp(nan,   1)), 'nan' )
  assertEquals( tostring(frexp(nan, nan)), 'nan' )
end

function TestLuaGmath:testRandom()
  for i=1,1000 do
    assertTrue( random()    >= 0   )
    assertTrue( random()    <  1   )
    assertTrue( random(100) >= 1   )
    assertTrue( random(100) <= 100 )
    assertTrue( random(-1,1) >= -1 )
    assertTrue( random(-1,1) <=  1 )
    assertTrue( random(-1,2^52) >= -1    )
    assertTrue( random(-1,2^52) <=  2^52 )
  end

  assertEquals( tostring(random(nan,  0 )), 'nan' )
  assertEquals( tostring(random( 0 , nan)), 'nan' )
  assertEquals( tostring(random(nan, nan)), 'nan' )
end

function TestLuaGmath:testRandomseed()
  local val  = {}
  local oldVal = {}
  for j=1,10 do
    randomseed( j )
    for i=1,500 do
      val[i] = random(0,2^52)
      assertTrue ( val[i] >= 0    )
      assertTrue ( val[i] <= 2^52 )
      assertFalse( val[i] == oldVal[i] )
      oldVal[i] = val[i]
    end
  end
end

-- extra generic functions

function TestLuaGmath:testAcosh()
  for _,v in ipairs(values.num) do
    v = v+1
    if v < inf then
      assertAlmostEquals( cosh(acosh(v)) / v, 1, v*eps )
    end
    if v > 1+1e-9 and v < huge then
      assertAlmostEquals( log(v+sqrt(v^2-1)) / acosh(v), 1 , eps )
    end
  end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(        1/acosh( 1    ) ,  inf  ) -- check for +0
  assertEquals(          acosh(inf   ) ,  inf  )
  assertEquals( tostring(acosh( 1-eps)), 'nan' )
  assertEquals( tostring(acosh( 0    )), 'nan' )
  assertEquals( tostring(acosh(nan   )), 'nan' )
end

function TestLuaGmath:testAngle()
  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    assertEquals( angle( x,  y), atan2( y,  x) )
    assertEquals( angle( x, -y), atan2(-y,  x) )
    assertEquals( angle(-x,  y), atan2( y, -x) )
    assertEquals( angle(-x, -y), atan2(-y, -x) )
  end end

  for _,x in ipairs(values.rad) do
  for _,y in ipairs(values.rad) do
    x, y = x/pi, y/pi
    assertEquals( angle( x,  y), atan2( y,  x) )
    assertEquals( angle( x, -y), atan2(-y,  x) )
    assertEquals( angle(-x,  y), atan2( y, -x) )
    assertEquals( angle(-x, -y), atan2(-y, -x) )
  end end

  assertEquals( angle(    0,    0),  0      )
  assertEquals( angle(    0,    1),  pi/2   )
  assertEquals( angle(    0, -  1), -pi/2   )
  assertEquals( angle(    0,  inf),  pi/2   )
  assertEquals( angle(    0, -inf), -pi/2   )
  assertEquals( angle(    1,    0),  0      )
  assertEquals( angle(    1,    1),  pi/4   )
  assertEquals( angle(    1, -  1), -pi/4   )
  assertEquals( angle(    1,  inf),  pi/2   )
  assertEquals( angle(    1, -inf), -pi/2   )
  assertEquals( angle( -  1,    0),  pi     )
  assertEquals( angle( -  1,    1),  pi/4*3 )
  assertEquals( angle( -  1, -  1), -pi/4*3 )
  assertEquals( angle( -  1,  inf),  pi/2   )
  assertEquals( angle( -  1, -inf), -pi/2   )
  assertEquals( angle(  inf,    0),  0      )
  assertEquals( angle(  inf,    1),  0      )
  assertEquals( angle(  inf, -  1),  0      )
  assertEquals( angle(  inf,  inf),  pi/4   )
  assertEquals( angle(  inf, -inf), -pi/4   )
  assertEquals( angle( -inf,    0),  pi     )
  assertEquals( angle( -inf,    1),  pi     )
  assertEquals( angle( -inf, -  1), -pi     )
  assertEquals( angle( -inf,  inf),  pi/4*3 )
  assertEquals( angle( -inf, -inf), -pi/4*3 )

  assertEquals( tostring(angle(nan, 0 )), 'nan' )
  assertEquals( tostring(angle( 0 ,nan)), 'nan' )
  assertEquals( tostring(angle(nan,nan)), 'nan' )
end

function TestLuaGmath:testAsinh()
  for _,v in ipairs(values.num) do
    if v < inf then
      assertAlmostEquals( asinh(v) - -asinh(-v), 0, eps )
    end
    if v > 0 and asinh(v) < 710 then -- skip huge
      assertAlmostEquals( sinh(asinh(v)) / v - 1       , 0, 15*eps )
      assertAlmostEquals( log(v+sqrt(v^2+1)) - asinh(v), 0, 16*eps )
    end
  end

  assertAlmostEquals( sinh(asinh(huge)) / huge - 1, 0, 400*eps )

  assertEquals( asinh(-inf), -inf )
  assertEquals( asinh(   0),    0 )
  assertEquals( asinh( inf),  inf )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals(        1/asinh(-0  ), -inf  ) -- check for -0
  assertEquals(        1/asinh( 0  ),  inf  ) -- check for +0
  assertEquals(          asinh(-inf), -inf  )
  assertEquals(          asinh( inf),  inf  )
  assertEquals( tostring(asinh(nan)), 'nan' )
end

function TestLuaGmath:testAtanh()
  for _,v in ipairs(values.rad) do
    if v/pi < 1 then -- skip inf
      assertAlmostEquals( atanh(v/pi) - -atanh(-v/pi), 0, eps )
    end
  end
  for _,v in ipairs(values.rad2) do
    assertAlmostEquals( atanh(tanh( v)) -  v, 0, 2*eps )
    assertAlmostEquals( atanh(tanh(-v)) - -v, 0, 2*eps )
  end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/atanh(-0), -inf ) -- check for -0
  assertEquals( 1/atanh( 0),  inf ) -- check for +0
  assertEquals(   atanh(-1), -inf )
  assertEquals(   atanh( 1),  inf )

  assertEquals( tostring(atanh(-1-eps)), 'nan' )
  assertEquals( tostring(atanh( 1+eps)), 'nan' )
  assertEquals( tostring(atanh(   nan)), 'nan' )
end

function TestLuaGmath:testErf()
  -- SetPrecision[Table[Erf[x],{x, 0, 0.1, 0.002}],20]
  local val1 = {0, 0.0022567553251835242509, 0.0045134925964086976269,
  0.0067701937601504658809, 0.0090268407637503350616, 0.011283415555849619569,
  0.013539900086822627759, 0.015796276309209784233, 0.018052526178150646308,
  0.020308631651816868441, 0.022564574691844942883, 0.024820337263768959407,
  0.027075901337453026768, 0.029331248887523666408, 0.031586361893801956358,
  0.033841222341735428814, 0.036095812222829884441, 0.038350113535080727900,
  0.040604108283404306834, 0.042857778480068768612, 0.045111106145124750533,
  0.047364073306835702271, 0.049616662002107868312, 0.051868854276919972024,
  0.054120632186752504200, 0.056371977797016629974, 0.058622873183482727966,
  0.060873300432708506158, 0.063123241642466618173, 0.065372678922171981175,
  0.067621594393308448456, 0.069869970189855162834, 0.072117788458712334121,
  0.074365031360126412907, 0.076611681068114972915, 0.078857719770890760680,
  0.081103129671285412172, 0.083347892987172433887, 0.085591991951889698220,
  0.087835408814661175558, 0.090078125841018152897, 0.092320125313219897345,
  0.094561389530673264914, 0.096801900810352198290, 0.099041641487215878459,
  0.10128059391462689021, 0.10351874046476788882, 0.10575606352905811414,
  0.10799254551856884987, 0.11022816886443817519, 0.11246291601828489748}
  -- SetPrecision[Table[Erf[x],{x, 0.1, 5, 0.1}],20]
  local val2 = {0.11246291601828489748, 0.22270258921047847434,
  0.32862675945912750430, 0.42839235504666856036, 0.52049987781304662970,
  0.60385609084792601919, 0.67780119383741843642, 0.74210096470766051535,
  0.79690821242283216286, 0.84270079294971489414, 0.88020506957408173321,
  0.91031397822963544542, 0.93400794494065242368, 0.95228511976264884620,
  0.96610514647531076093, 0.97634838334464402188, 0.98379045859077451919,
  0.98909050163573075665, 0.99279042923525750997, 0.99532226501895271209,
  0.99702053334366702586, 0.99813715370201816501, 0.99885682340264336787,
  0.99931148610335496230, 0.99959304798255499414, 0.99976396558347069288,
  0.99986566726005943195, 0.99992498680533459243, 0.99995890212190052804,
  0.99997790950300136092, 0.99998835134263275304, 0.99999397423884828218,
  0.99999694229020352765, 0.99999847800663710373, 0.99999925690162760894,
  0.99999964413700703769, 0.99999983284894211621, 0.99999992299607254331,
  0.99999996520775136233, 0.99999998458274208524, 0.99999999329997235620,
  0.99999999714450582555, 0.99999999880652823414, 0.9999999995108289630,
  0.9999999998033839432, 0.9999999999225039904, 0.9999999999700474040,
  0.9999999999886478586, 0.9999999999957810415, 0.9999999999984625632}

  local i
  i=0 for v=0,0.1,0.002 do i=i+1
    assertAlmostEquals( erf(v) - val1[i], 0, eps )
  end
  i=0 for v=0.1,5,0.1 do i=i+1
    assertAlmostEquals( erf(v) - val2[i], 0, eps )
  end

  for _,v in ipairs(values.num) do
    assertAlmostEquals( erf(v) - -erf(-v), 0, eps )
  end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/erf(-  0), -inf ) -- check for -0
  assertEquals( 1/erf(   0),  inf ) -- check for +0
  assertEquals(   erf(-inf), - 1  )
  assertEquals(   erf( inf),   1  )

  assertEquals( tostring(erf(nan)), 'nan' )
end

function TestLuaGmath:testFrac()
  for _,v in ipairs(values.num) do
    if v == inf then break end -- pb, see below
    assertEquals( frac( v+eps), second(modf( v+eps)) )
    assertEquals( frac( v-eps), second(modf( v-eps)) )
    assertEquals( frac(-v+eps), second(modf(-v+eps)) )
    assertEquals( frac(-v-eps), second(modf(-v-eps)) )
    assertEquals( frac( v+0.1), second(modf( v+0.1)) )
    assertEquals( frac( v-0.1), second(modf( v-0.1)) )
    assertEquals( frac(-v+0.1), second(modf(-v+0.1)) )
    assertEquals( frac(-v-0.1), second(modf(-v-0.1)) )
    assertEquals( frac( v+0.7), second(modf( v+0.7)) )
    assertEquals( frac( v-0.7), second(modf( v-0.7)) )
    assertEquals( frac(-v+0.7), second(modf(-v+0.7)) )
    assertEquals( frac(-v-0.7), second(modf(-v-0.7)) )
  end

  assertEquals( frac(    0) ,     0 )
  assertEquals( frac( tiny) ,  tiny )
  assertEquals( frac(  0.1) ,   0.1 )
  assertEquals( frac(  0.5) ,   0.5 )
  assertEquals( frac(  0.7) ,   0.7 )
  assertEquals( frac(    1) ,     0 )
  assertEquals( frac(  1.5) ,   0.5 )
  assertEquals( frac(  1.7) ,   0.7 )
  assertEquals( frac( huge) ,     0 )
!  assertEquals( frac(  inf) ,     0 ) -- get nan, pb with modf and jit
  assertEquals( frac(-   0) , -   0 )
  assertEquals( frac(-tiny) , -tiny )
  assertEquals( frac(- 0.1) , - 0.1 )
  assertEquals( frac(- 0.5) , - 0.5 )
  assertEquals( frac(- 0.7) , - 0.7 )
  assertEquals( frac(-   1) , -   0 )
  assertEquals( frac(- 1.5) , - 0.5 )
  assertEquals( frac(- 1.7) , - 0.7 )
  assertEquals( frac(-huge) , -   0 )
!  assertTrue  ( frac(- inf) ,     0 ) -- get nan, pb with modf and jit

  assertAlmostEquals( frac( 1.1)-0.1, 0, eps/2 )
  assertAlmostEquals( frac(-1.1)+0.1, 0, eps/2 )

  assertEquals( tostring(frac(nan)), 'nan' )
end

function TestLuaGmath:testTGamma()
  local fact
  fact = function(n) return n <= 1 and 1 or n*fact(n-1) end

  -- SetPrecision[Table[Gamma[x],{x, 0.01, 1, 0.03}],20]
  local val1 = {99.432585119150616038, 24.460955022856119001,
  13.773600607733806456, 9.5135076986687305833, 7.2302419210119861503,
  5.8112691664561264560, 4.8467633533349454567, 4.1504815795927783029,
  3.6256099082219082064, 3.2168517018296229892, 2.8903360540117146726,
  2.6241632564984840315, 2.4035500200786530378, 2.2181595437576882013,
  2.0605493863359747309, 1.9252268183155301084, 1.8080512889238926633,
  1.7058438140839640162, 1.6161242687335750645, 1.5369302649435188091,
  1.4666895221797529025, 1.4041281721350677980, 1.3482037306042777836,
  1.2980553326475579023, 1.2529662618990031753, 1.2123353744883700323,
  1.1756550511468120135, 1.1424940039550788295, 1.1124837369484652516,
  1.0853077874677194981, 1.0606931055726904756, 1.0384030930559640105,
  1.0182319420865892923, 1}
  -- SetPrecision[Table[Gamma[x],{x, 1, 10, 0.3}],20]
  local val2 = {1, 0.89747069630627729353,
  0.89351534928769016375, 0.96176583190738740292, 1.1018024908797128258,
  1.3293403881791370225, 1.6764907877644363854, 2.1976202783924772000,
  2.9812064268103326548, 4.1706517837966021744, 6.0000000000000000000,
  8.8553433604540359170, 13.381285870932442705, 20.667385961857860366,
  32.578096050331353695, 52.342777784553518927, 85.621737512705280437,
  142.45194406567867418, 240.83377998344568027, 413.40751676527088421,
  720.00000000000000000, 1271.4236336639089586, 2275.0326986324494101,
  4122.7094842854376111, 7562.2882799713024724, 14034.407293483413014,
  26339.986354508604563, 49973.708949624793604, 95809.457688134469208,
  185550.93597230646992, 362880}
  -- http://oeis.org/A030169
  local xmin, ymin = 1.46163214496836234126, 0.88560319441088870028

  local i
  i=0 for v=0.01,1,0.03 do i=i+1 -- should be done with range
    v=0.01+0.03*(i-1)
    assertAlmostEquals( tgamma(v)/val1[i] -1, 0, eps )
  end
  i=0 for v=1,10,0.3 do i=i+1 -- should be done with range
    v=1+0.3*(i-1)
    assertAlmostEquals( tgamma(v)/val2[i] -1, 0, eps )
  end

  for n=1,20 do
    assertAlmostEquals( tgamma(n)/fact(n-1)       -1, 0, log(fact(n)) *   eps )
  end
  i=0 for v=1,171.6,0.1 do i=i+1 -- should be done with range
    v=1+0.1*(i-1)
    assertAlmostEquals( tgamma(v)/(tgamma(1+v)/v) -1, 0, log(fact(v)) *11*eps )
  end

  assertEquals( tgamma(  1),    1 )
  assertEquals( tgamma(  2),    1 )
  assertEquals( tgamma(  3),    2 )
  assertEquals( tgamma(  4),    6 )
  assertEquals( tgamma(xmin), ymin )
  assertAlmostEquals( tgamma( 0.5), sqrt(pi), eps )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( tgamma(- 0 ), -inf )
  assertEquals( tgamma(  0 ),  inf )
  assertEquals( tgamma( inf),  inf )

  assertEquals( tostring(tgamma(-   1)), 'nan' )
  assertEquals( tostring(tgamma(-   2)), 'nan' )
  assertEquals( tostring(tgamma(-2^52)), 'nan' )
  assertEquals( tostring(tgamma(- inf)), 'nan' )
  assertEquals( tostring(tgamma(  nan)), 'nan' )
end

function TestLuaGmath:testLGamma()
  local lfact
  lfact = function(n) return n <= 1 and 0 or log(n)+lfact(n-1) end

  -- Note: This test is failing on Ubuntu 14.04
  -- The C function lgamma is returning incorrect values. This might be a
  -- linking problem between mad (luajit) and libm because printing the value
  -- returned in mad_num.c already shows the problem, while a free standing C
  -- application gives correct values, i.e. lgamma itself works fine.

  for n=3,100 do
    assertAlmostEquals( lgamma(n)/lfact(n-1)           -1, 0, 2*eps )
  end
  for v=3,171,0.1 do
    assertAlmostEquals( lgamma(v)/(lgamma(1+v)-log(v)) -1, 0, 4*eps )
  end

  assertEquals( lgamma(-0), -inf )
  assertEquals( lgamma( 0),  inf )

  assertAlmostEquals( lgamma(-0.5), 1.265512123484645297, 0)
  assertAlmostEquals( lgamma( 0.5), log(sqrt(pi)), 0)
  assertAlmostEquals( lgamma( 3  ), log(2), eps )
  assertAlmostEquals( lgamma( 4  ), log(6), eps )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( lgamma(    1),    0 )
  assertEquals( lgamma(    2),    0 )
  assertEquals( lgamma(- inf),  inf )
  assertEquals( lgamma(-2^52),  inf )
  assertEquals( lgamma(-   2),  inf )
  assertEquals( lgamma(-   1),  inf )
  assertEquals( lgamma(  inf),  inf )

  assertEquals( tostring(lgamma(nan)), 'nan' )
end

function TestLuaGmath:testRound()
  assertEquals( round( tiny) ,     0 )
  assertEquals( round(  0.1) ,     0 )
  assertEquals( round(  0.5) ,     1 )
  assertEquals( round(  0.7) ,     1 )
  assertEquals( round(    1) ,     1 )
  assertEquals( round(  1.1) ,     1 )
  assertEquals( round(  1.5) ,     2 )
  assertEquals( round(  1.7) ,     2 )
  assertEquals( round( huge) ,  huge )
  assertEquals( round(-tiny) , -   0 )
  assertEquals( round(- 0.1) , -   0 )
  assertEquals( round(- 0.5) , -   1 )
  assertEquals( round(- 0.7) , -   1 )
  assertEquals( round(-   1) , -   1 )
  assertEquals( round(- 1.1) , -   1 )
  assertEquals( round(- 1.5) , -   2 )
  assertEquals( round(- 1.7) , -   2 )
  assertEquals( round(-huge) , -huge )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/round(-  0 ) , -inf ) -- check for -0
  assertEquals( 1/round(   0 ) ,  inf ) -- check for +0
  assertEquals(   round(- inf) , -inf )
  assertEquals(   round(  inf) ,  inf )

  assertEquals( tostring(round(nan)), 'nan' )
end

function TestLuaGmath:testSign()
  assertEquals( sign(    0) ,  1 )
  assertEquals( sign( tiny) ,  1 )
  assertEquals( sign(  0.1) ,  1 )
  assertEquals( sign(    1) ,  1 )
  assertEquals( sign( huge) ,  1 )
  assertEquals( sign(  inf) ,  1 )
  assertEquals( sign(-   0) ,  1 )
  assertEquals( sign(-tiny) , -1 )
  assertEquals( sign(- 0.1) , -1 )
  assertEquals( sign(-   1) , -1 )
  assertEquals( sign(-huge) , -1 )
  assertEquals( sign(- inf) , -1 )

  assertEquals( tostring(sign(nan)), 'nan' )
end

function TestLuaGmath:testSinc()
  for _,v in ipairs(values.num) do
    if v < 1e-7 then
      assertEquals( sinc( v), 1 )
      assertEquals( sinc(-v), 1 )
    elseif v < inf then
      assertEquals( sinc( v), sinc(-v) )
      assertEquals( sinc( v), sin(v) / v )
      assertEquals( sinc(-v), sin(-v)/-v )
    end
  end

  assertEquals( tostring(sinc(-inf)), 'nan' )
  assertEquals( tostring(sinc( inf)), 'nan' )
  assertEquals( tostring(sinc( nan)), 'nan' )
end

function TestLuaGmath:testStep()
  assertEquals( step(    0) , 1 )
  assertEquals( step( tiny) , 1 )
  assertEquals( step(  0.1) , 1 )
  assertEquals( step(    1) , 1 )
  assertEquals( step( huge) , 1 )
  assertEquals( step(  inf) , 1 )
  assertEquals( step(-   0) , 1 )
  assertEquals( step(-tiny) , 0 )
  assertEquals( step(- 0.1) , 0 )
  assertEquals( step(-   1) , 0 )
  assertEquals( step(-huge) , 0 )
  assertEquals( step(- inf) , 0 )

  assertEquals( tostring(step(nan)), 'nan' )
end

function TestLuaGmath:testTrunc()
  for _,v in ipairs(values.num) do
    assertEquals( trunc( v+eps), first(modf( v+eps)) )
    assertEquals( trunc( v-eps), first(modf( v-eps)) )
    assertEquals( trunc(-v+eps), first(modf(-v+eps)) )
    assertEquals( trunc(-v-eps), first(modf(-v-eps)) )
    assertEquals( trunc( v+0.1), first(modf( v+0.1)) )
    assertEquals( trunc( v-0.1), first(modf( v-0.1)) )
    assertEquals( trunc(-v+0.1), first(modf(-v+0.1)) )
    assertEquals( trunc(-v-0.1), first(modf(-v-0.1)) )
    assertEquals( trunc( v+0.7), first(modf( v+0.7)) )
    assertEquals( trunc( v-0.7), first(modf( v-0.7)) )
    assertEquals( trunc(-v+0.7), first(modf(-v+0.7)) )
    assertEquals( trunc(-v-0.7), first(modf(-v-0.7)) )
  end

  assertEquals( trunc( tiny) ,     0 )
  assertEquals( trunc(  0.1) ,     0 )
  assertEquals( trunc(  0.5) ,     0 )
  assertEquals( trunc(  0.7) ,     0 )
  assertEquals( trunc(    1) ,     1 )
  assertEquals( trunc(  1.1) ,     1 )
  assertEquals( trunc(  1.5) ,     1 )
  assertEquals( trunc(  1.7) ,     1 )
  assertEquals( trunc( huge) ,  huge )
  assertEquals( trunc(-tiny) , -   0 )
  assertEquals( trunc(- 0.1) , -   0 )
  assertEquals( trunc(- 0.5) , -   0 )
  assertEquals( trunc(- 0.7) , -   0 )
  assertEquals( trunc(-   1) , -   1 )
  assertEquals( trunc(- 1.1) , -   1 )
  assertEquals( trunc(- 1.5) , -   1 )
  assertEquals( trunc(- 1.7) , -   1 )
  assertEquals( trunc(-huge) , -huge )

  -- Check for IEEE:IEC 60559 compliance
  assertEquals( 1/trunc(-  0 ) , -inf ) -- check for -0
  assertEquals( 1/trunc(   0 ) ,  inf ) -- check for +0
  assertEquals(   trunc(- inf) , -inf )
  assertEquals(   trunc(  inf) ,  inf )

  assertEquals( tostring(trunc(nan)), 'nan' )
end

-- operators as functions

function TestLuaGmath:testMulOp()
  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x > tiny and y > tiny and x < huge and y < huge then
      assertEquals      (  mul(x,y), mul(y,x) )
      assertAlmostEquals( (mul(x,y)/y - x)/x, 0, eps )
    end
  end end

  assertEquals( mul(   0,   1),    0 )
  assertEquals( mul(   0,-  1), -  0 )
  assertEquals( mul(-  0,   1), -  0 )
  assertEquals( mul(-  0,-  1),    0 )

  assertEquals( mul(   1, inf),  inf )
  assertEquals( mul(   1,-inf), -inf )
  assertEquals( mul(-  1, inf), -inf )
  assertEquals( mul(-  1,-inf),  inf )

  assertEquals( mul( inf,   1),  inf )
  assertEquals( mul(-inf,   1), -inf )
  assertEquals( mul( inf,-  1), -inf )
  assertEquals( mul(-inf,-  1),  inf )

  assertEquals( mul( inf, inf),  inf )
  assertEquals( mul(-inf, inf), -inf )
  assertEquals( mul( inf,-inf), -inf )
  assertEquals( mul(-inf,-inf),  inf )

  assertEquals( tostring(mul(   0, inf)), 'nan' )
  assertEquals( tostring(mul(   0,-inf)), 'nan' )
  assertEquals( tostring(mul(-  0, inf)), 'nan' )
  assertEquals( tostring(mul(-  0,-inf)), 'nan' )

  assertEquals( tostring(mul( inf,   0)), 'nan' )
  assertEquals( tostring(mul(-inf,   0)), 'nan' )
  assertEquals( tostring(mul( inf,-  0)), 'nan' )
  assertEquals( tostring(mul(-inf,-  0)), 'nan' )

  assertEquals( tostring(mul(  0 , nan)), 'nan' )
  assertEquals( tostring(mul( nan,  0 )), 'nan' )
  assertEquals( tostring(mul(  1 , nan)), 'nan' )
  assertEquals( tostring(mul( nan,  1 )), 'nan' )
end

function TestLuaGmath:testDivOp()
  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x > tiny and y > tiny and x < huge and y < huge then
      assertAlmostEquals( (div(x,y)*y - x)/x, 0, eps )
    end
  end end

  assertEquals( 1/div(   0,   1),  inf ) -- check for +0
  assertEquals( 1/div(   0,-  1), -inf ) -- check for -0
  assertEquals( 1/div(-  0,   1), -inf ) -- check for -0
  assertEquals( 1/div(-  0,-  1),  inf ) -- check for +0

  assertEquals(   div(   1,   0),  inf )
  assertEquals(   div(-  1,   0), -inf )
  assertEquals(   div(   1,-  0), -inf )
  assertEquals(   div(-  1,-  0),  inf )

  assertEquals( 1/div(   0, inf),  inf ) -- check for +0
  assertEquals( 1/div(   0,-inf), -inf ) -- check for -0
  assertEquals( 1/div(-  0, inf), -inf ) -- check for -0
  assertEquals( 1/div(-  0,-inf),  inf ) -- check for +0

  assertEquals(   div( inf,   0),  inf )
  assertEquals(   div(-inf,   0), -inf )
  assertEquals(   div( inf,-  0), -inf )
  assertEquals(   div(-inf,-  0),  inf )

  assertEquals( 1/div(   1, inf),  inf ) -- check for +0
  assertEquals( 1/div(   1,-inf), -inf ) -- check for -0
  assertEquals( 1/div(-  1, inf), -inf ) -- check for -0
  assertEquals( 1/div(-  1,-inf),  inf ) -- check for +0

  assertEquals(   div( inf,   1),  inf )
  assertEquals(   div(-inf,   1), -inf )
  assertEquals(   div( inf,-  1), -inf )
  assertEquals(   div(-inf,-  1),  inf )

  assertEquals( tostring(div( inf, inf)), 'nan' )
  assertEquals( tostring(div(-inf, inf)), 'nan' )
  assertEquals( tostring(div( inf,-inf)), 'nan' )
  assertEquals( tostring(div(-inf,-inf)), 'nan' )

  assertEquals( tostring(div( 0, 0)), 'nan' )
  assertEquals( tostring(div( 0,-0)), 'nan' )
  assertEquals( tostring(div(-0, 0)), 'nan' )
  assertEquals( tostring(div(-0,-0)), 'nan' )

  assertEquals( tostring(div( 0 , nan)), 'nan' )
  assertEquals( tostring(div(nan,  0 )), 'nan' )
  assertEquals( tostring(div( 1 , nan)), 'nan' )
  assertEquals( tostring(div(nan,  1 )), 'nan' )
end

function TestLuaGmath:testModOp()
  -- Lua: a % b == a - math.floor(a/b)*b
  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if y > 0 and y < inf and x < inf then
      assertEquals( x%y , x - floor(x/y)*y )
    end
  end end

  assertAlmostEquals( mod(-5.1, -3  ) - -2.1, 0, 2*eps)
  assertAlmostEquals( mod(-5.1,  3  ) -  0.9, 0, 2*eps)
  assertAlmostEquals( mod( 5.1, -3  ) - -0.9, 0, 2*eps)
  assertAlmostEquals( mod( 5.1,  3  ) -  2.1, 0, 2*eps)

  assertAlmostEquals( mod(-5.1, -3.1) - -2  , 0, 2*eps)
  assertAlmostEquals( mod(-5.1,  3.1) -  1.1, 0, 2*eps)
  assertAlmostEquals( mod( 5.1, -3.1) - -1.1, 0, 2*eps)
  assertAlmostEquals( mod( 5.1,  3.1) -  2  , 0, 2*eps)

  assertEquals( tostring(mod( 1,  inf)), 'nan' )
  assertEquals( tostring(mod(-1,  inf)), 'nan' )
  assertEquals( tostring(mod( 1, -inf)), 'nan' )
  assertEquals( tostring(mod(-1, -inf)), 'nan' )

  assertEquals( tostring(mod( inf,  inf)), 'nan' )
  assertEquals( tostring(mod(-inf, -inf)), 'nan' )
  assertEquals( tostring(mod( inf,  nan)), 'nan' )
  assertEquals( tostring(mod(-inf,  nan)), 'nan' )
  assertEquals( tostring(mod(   1,    0)), 'nan' )
  assertEquals( tostring(mod(   1,  - 0)), 'nan' )
  assertEquals( tostring(mod( nan,  nan)), 'nan' )
end

function TestLuaGmath:testPowOp()
  local pow = function(a,b) return a^b end -- see testPow

  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x > 1/709.78 and y > 1/709.78 and x < 709.78 and y < 709.78 then
      assertAlmostEquals( log(pow(x,y)) - y*log(x), 0, max(abs(y*log(x)) * eps, eps) )
    end
  end end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals   (pow(  0 , - 11),  inf )
  assertEquals   (pow(- 0 , - 11), -inf )

  assertEquals   (pow(  0 , - .5),  inf )
  assertEquals   (pow(- 0 , - .5),  inf )
  assertEquals   (pow(  0 , -  2),  inf )
  assertEquals   (pow(- 0 , -  2),  inf )
  assertEquals   (pow(  0 , - 10),  inf )
  assertEquals   (pow(- 0 , - 10),  inf )

  assertEquals( 1/pow(  0 ,    1),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,    1), -inf ) -- check for -0
  assertEquals( 1/pow(  0 ,   11),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,   11), -inf ) -- check for -0

  assertEquals( 1/pow(  0 ,  0.5),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,  0.5),  inf ) -- check for +0
  assertEquals( 1/pow(  0 ,    2),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,    2),  inf ) -- check for +0
  assertEquals( 1/pow(  0 ,   10),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,   10),  inf ) -- check for +0
  assertEquals( 1/pow(  0 ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(- 0 ,  inf),  inf ) -- check for +0

  assertEquals   (pow(- 1 ,  inf),   1  )
  assertEquals   (pow(- 1 , -inf),   1  )

  assertEquals   (pow(  1 ,   0 ),   1  )
  assertEquals   (pow(  1 , - 0 ),   1  )
  assertEquals   (pow(  1 ,  0.5),   1  )
  assertEquals   (pow(  1 , -0.5),   1  )
  assertEquals   (pow(  1 ,   1 ),   1  )
  assertEquals   (pow(  1 , - 1 ),   1  )
  assertEquals   (pow(  1 ,  inf),   1  )
  assertEquals   (pow(  1 , -inf),   1  )
  assertEquals   (pow(  1 ,  nan),   1  )
  assertEquals   (pow(  1 , -nan),   1  )

  assertEquals   (pow(  0 ,   0 ),   1  )
  assertEquals   (pow(- 0 ,   0 ),   1  )
  assertEquals   (pow( 0.5,   0 ),   1  )
  assertEquals   (pow(-0.5,   0 ),   1  )
  assertEquals   (pow(  1 ,   0 ),   1  )
  assertEquals   (pow(- 1 ,   0 ),   1  )
  assertEquals   (pow( inf,   0 ),   1  )
  assertEquals   (pow(-inf,   0 ),   1  )
  assertEquals   (pow( nan,   0 ),   1  )
  assertEquals   (pow(-nan,   0 ),   1  )

  assertEquals   (pow(  0 , - 0 ),   1  )
  assertEquals   (pow(- 0 , - 0 ),   1  )
  assertEquals   (pow( 0.5, - 0 ),   1  )
  assertEquals   (pow(-0.5, - 0 ),   1  )
  assertEquals   (pow(  1 , - 0 ),   1  )
  assertEquals   (pow(- 1 , - 0 ),   1  )
  assertEquals   (pow( inf, - 0 ),   1  )
  assertEquals   (pow(-inf, - 0 ),   1  )
  assertEquals   (pow( nan, - 0 ),   1  )
  assertEquals   (pow(-nan, - 0 ),   1  )

  assertEquals   ( tostring(pow(- 1  , 0.5)), 'nan' )
  assertEquals   ( tostring(pow(- 1  ,-0.5)), 'nan' )
  assertEquals   ( tostring(pow(- 1  , 1.5)), 'nan' )
  assertEquals   ( tostring(pow(- 1  ,-1.5)), 'nan' )

  assertEquals   (pow(  0   , -inf),  inf )
  assertEquals   (pow(- 0   , -inf),  inf )
  assertEquals   (pow( 0.5  , -inf),  inf )
  assertEquals   (pow(-0.5  , -inf),  inf )
  assertEquals   (pow( 1-eps, -inf),  inf )
  assertEquals   (pow(-1+eps, -inf),  inf )

  assertEquals( 1/pow( 1+eps, -inf),  inf ) -- check for +0
  assertEquals( 1/pow(-1-eps, -inf),  inf ) -- check for +0
  assertEquals( 1/pow( 1.5  , -inf),  inf ) -- check for +0
  assertEquals( 1/pow(-1.5  , -inf),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , -inf),  inf ) -- check for +0
  assertEquals( 1/pow(-inf  , -inf),  inf ) -- check for +0

  assertEquals( 1/pow(  0   ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(- 0   ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow( 0.5  ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(-0.5  ,  inf),  inf ) -- check for +0
  assertEquals( 1/pow( 1-eps,  inf),  inf ) -- check for +0
  assertEquals( 1/pow(-1+eps,  inf),  inf ) -- check for +0

  assertEquals   (pow( 1+eps,  inf),  inf )
  assertEquals   (pow(-1-eps,  inf),  inf )
  assertEquals   (pow( 1.5  ,  inf),  inf )
  assertEquals   (pow(-1.5  ,  inf),  inf )
  assertEquals   (pow( inf  ,  inf),  inf )
  assertEquals   (pow(-inf  ,  inf),  inf )

  assertEquals( 1/pow(-inf  , -  1), -inf ) -- check for -0
  assertEquals( 1/pow(-inf  , - 11), -inf ) -- check for -0
  assertEquals( 1/pow(-inf  , -0.5),  inf ) -- check for +0
  assertEquals( 1/pow(-inf  , -  2),  inf ) -- check for +0
  assertEquals( 1/pow(-inf  , - 10),  inf ) -- check for +0

  assertEquals  ( pow(-inf  ,    1), -inf )
  assertEquals  ( pow(-inf  ,   11), -inf )
  assertEquals  ( pow(-inf  ,  0.5),  inf )
  assertEquals  ( pow(-inf  ,    2),  inf )
  assertEquals  ( pow(-inf  ,   10),  inf )

  assertEquals( 1/pow( inf  , -0.5),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , -  1),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , -  2),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , - 10),  inf ) -- check for +0
  assertEquals( 1/pow( inf  , - 11),  inf ) -- check for +0

  assertEquals  ( pow( inf  ,  0.5),  inf )
  assertEquals  ( pow( inf  ,    1),  inf )
  assertEquals  ( pow( inf  ,    2),  inf )
  assertEquals  ( pow( inf  ,   10),  inf )
  assertEquals  ( pow( inf  ,   11),  inf )

  assertEquals   ( tostring(pow( 0  ,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-0  ,  nan)), 'nan' )
  assertEquals   ( tostring(pow( 0  , -nan)), 'nan' )
  assertEquals   ( tostring(pow(-0  , -nan)), 'nan' )

  assertEquals   ( tostring(pow(-1  ,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-1  , -nan)), 'nan' )
  assertEquals   ( tostring(pow( nan,   1 )), 'nan' )
  assertEquals   ( tostring(pow(-nan,   1 )), 'nan' )
  assertEquals   ( tostring(pow( nan, - 1 )), 'nan' )
  assertEquals   ( tostring(pow(-nan, - 1 )), 'nan' )

  assertEquals   ( tostring(pow( inf,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-inf,  nan)), 'nan' )
  assertEquals   ( tostring(pow( inf, -nan)), 'nan' )
  assertEquals   ( tostring(pow(-inf, -nan)), 'nan' )
  assertEquals   ( tostring(pow( nan,  inf)), 'nan' )
  assertEquals   ( tostring(pow(-nan,  inf)), 'nan' )
  assertEquals   ( tostring(pow( nan, -inf)), 'nan' )
  assertEquals   ( tostring(pow(-nan, -inf)), 'nan' )

  assertEquals   ( tostring(pow( nan,  nan)), 'nan' )
  assertEquals   ( tostring(pow(-nan,  nan)), 'nan' )
  assertEquals   ( tostring(pow( nan, -nan)), 'nan' )
  assertEquals   ( tostring(pow(-nan, -nan)), 'nan' )
end

function TestLuaGmath:testPowOp2()
  for _,x in ipairs(values.num) do
  for _,y in ipairs(values.num) do
    if x > 1/709.78 and y > 1/709.78 and x < 709.78 and y < 709.78 then
      assertAlmostEquals( log(x^y) - y*log(x), 0, max(abs(y*log(x)) * eps, eps) )
    end
  end end

  -- Check for IEEE:IEC 60559 compliance
  assertEquals   (   0 ^ - 11,  inf )
  assertEquals   ( - 0 ^ - 11, -inf )

  assertEquals   (   0 ^ - .5,  inf )
  assertEquals   ((- 0)^ - .5,  inf )
  assertEquals   (   0 ^ -  2,  inf )
  assertEquals   ((- 0)^ -  2,  inf )
  assertEquals   (   0 ^ - 10,  inf )
  assertEquals   ((- 0)^ - 10,  inf )

  assertEquals( 1/   0 ^    1,  inf ) -- check for +0
  assertEquals( 1/(- 0)^    1, -inf ) -- check for -0
  assertEquals( 1/   0 ^   11,  inf ) -- check for +0
  assertEquals( 1/(- 0)^   11, -inf ) -- check for -0

  assertEquals( 1/   0 ^  0.5,  inf ) -- check for +0
  assertEquals( 1/(- 0)^  0.5,  inf ) -- check for +0
  assertEquals( 1/   0 ^    2,  inf ) -- check for +0
  assertEquals( 1/(- 0)^    2,  inf ) -- check for +0
  assertEquals( 1/   0 ^   10,  inf ) -- check for +0
  assertEquals( 1/(- 0)^   10,  inf ) -- check for +0
  assertEquals( 1/   0 ^  inf,  inf ) -- check for +0
  assertEquals( 1/(- 0)^  inf,  inf ) -- check for +0

  assertEquals   ((- 1)^  inf,   1  )
  assertEquals   ((- 1)^ -inf,   1  )

  assertEquals   (   1 ^   0 ,   1  )
  assertEquals   (   1 ^ - 0 ,   1  )
  assertEquals   (   1 ^  0.5,   1  )
  assertEquals   (   1 ^ -0.5,   1  )
  assertEquals   (   1 ^   1 ,   1  )
  assertEquals   (   1 ^ - 1 ,   1  )
  assertEquals   (   1 ^  inf,   1  )
  assertEquals   (   1 ^ -inf,   1  )
  assertEquals   (   1 ^  nan,   1  )
  assertEquals   (   1 ^ -nan,   1  )

  assertEquals   (   0  ^  0 ,   1  )
  assertEquals   ((- 0 )^  0 ,   1  )
  assertEquals   (  0.5 ^  0 ,   1  )
  assertEquals   ((-0.5)^  0 ,   1  )
  assertEquals   (   1  ^  0 ,   1  )
  assertEquals   ((- 1 )^  0 ,   1  )
  assertEquals   (  inf ^  0 ,   1  )
  assertEquals   ((-inf)^  0 ,   1  )
  assertEquals   (  nan ^  0 ,   1  )
  assertEquals   ((-nan)^  0 ,   1  )

  assertEquals   (   0  ^- 0 ,   1  )
  assertEquals   ((- 0 )^- 0 ,   1  )
  assertEquals   (  0.5 ^- 0 ,   1  )
  assertEquals   ((-0.5)^- 0 ,   1  )
  assertEquals   (   1  ^- 0 ,   1  )
  assertEquals   ((- 1 )^- 0 ,   1  )
  assertEquals   (  inf ^- 0 ,   1  )
  assertEquals   ((-inf)^- 0 ,   1  )
  assertEquals   (  nan ^- 0 ,   1  )
  assertEquals   ((-nan)^- 0 ,   1  )

  assertEquals   ( tostring((- 1)^ 0.5), 'nan' )
  assertEquals   ( tostring((- 1)^-0.5), 'nan' )
  assertEquals   ( tostring((- 1)^ 1.5), 'nan' )
  assertEquals   ( tostring((- 1)^-1.5), 'nan' )

  assertEquals   (   0    ^ -inf,  inf )
  assertEquals   ((- 0   )^ -inf,  inf )
  assertEquals   (  0.5   ^ -inf,  inf )
  assertEquals   ((-0.5  )^ -inf,  inf )
  assertEquals   (( 1-eps)^ -inf,  inf )
  assertEquals   ((-1+eps)^ -inf,  inf )

  assertEquals(1/(( 1+eps)^ -inf), inf ) -- check for +0
  assertEquals(1/((-1-eps)^ -inf), inf ) -- check for +0
  assertEquals(1/( 1.5    ^ -inf), inf ) -- check for +0
  assertEquals(1/((-1.5  )^ -inf), inf ) -- check for +0
  assertEquals(1/( inf    ^ -inf), inf ) -- check for +0
  assertEquals(1/((-inf  )^ -inf), inf ) -- check for +0

  assertEquals(1/(     0  ^  inf), inf ) -- check for +0
  assertEquals(1/((-   0 )^  inf), inf ) -- check for +0
  assertEquals(1/(    0.5 ^  inf), inf ) -- check for +0
  assertEquals(1/((-  0.5)^  inf), inf ) -- check for +0
  assertEquals(1/(( 1-eps)^  inf), inf ) -- check for +0
  assertEquals(1/((-1+eps)^  inf), inf ) -- check for +0

  assertEquals   (( 1+eps)^  inf,  inf )
  assertEquals   ((-1-eps)^  inf,  inf )
  assertEquals   (  1.5   ^  inf,  inf )
  assertEquals   ((-1.5  )^  inf,  inf )
  assertEquals   (  inf   ^  inf,  inf )
  assertEquals   ((-inf  )^  inf,  inf )

  assertEquals( 1/((-inf) ^ -  1), -inf ) -- check for -0
  assertEquals( 1/((-inf) ^ - 11), -inf ) -- check for -0
  assertEquals( 1/((-inf) ^ -0.5),  inf ) -- check for +0
  assertEquals( 1/((-inf) ^ -  2),  inf ) -- check for +0
  assertEquals( 1/((-inf) ^ - 10),  inf ) -- check for +0

  assertEquals  (  (-inf) ^    1 , -inf )
  assertEquals  (  (-inf) ^   11 , -inf )
  assertEquals  (  (-inf) ^  0.5 ,  inf )
  assertEquals  (  (-inf) ^    2 ,  inf )
  assertEquals  (  (-inf) ^   10 ,  inf )

  assertEquals( 1/(  inf  ^ -0.5),  inf ) -- check for +0
  assertEquals( 1/(  inf  ^ -  1),  inf ) -- check for +0
  assertEquals( 1/(  inf  ^ -  2),  inf ) -- check for +0
  assertEquals( 1/(  inf  ^ - 10),  inf ) -- check for +0
  assertEquals( 1/(  inf  ^ - 11),  inf ) -- check for +0

  assertEquals  (    inf  ^  0.5 ,  inf )
  assertEquals  (    inf  ^    1 ,  inf )
  assertEquals  (    inf  ^    2 ,  inf )
  assertEquals  (    inf  ^   10 ,  inf )
  assertEquals  (    inf  ^   11 ,  inf )

  assertEquals   ( tostring(  0   ^  nan), 'nan' )
  assertEquals   ( tostring((-0  )^  nan), 'nan' )
  assertEquals   ( tostring(  0   ^ -nan), 'nan' )
  assertEquals   ( tostring((-0  )^ -nan), 'nan' )

  assertEquals   ( tostring((-1  )^  nan), 'nan' )
  assertEquals   ( tostring((-1  )^ -nan), 'nan' )
  assertEquals   ( tostring(  nan ^   1 ), 'nan' )
  assertEquals   ( tostring((-nan)^   1 ), 'nan' )
  assertEquals   ( tostring(  nan ^ - 1 ), 'nan' )
  assertEquals   ( tostring((-nan)^ - 1 ), 'nan' )

  assertEquals   ( tostring(  inf ^  nan), 'nan' )
  assertEquals   ( tostring((-inf)^  nan), 'nan' )
  assertEquals   ( tostring(  inf ^ -nan), 'nan' )
  assertEquals   ( tostring((-inf)^ -nan), 'nan' )
  assertEquals   ( tostring(  nan ^  inf), 'nan' )
  assertEquals   ( tostring((-nan)^  inf), 'nan' )
  assertEquals   ( tostring(  nan ^ -inf), 'nan' )
  assertEquals   ( tostring((-nan)^ -inf), 'nan' )

  assertEquals   ( tostring(  nan ^  nan), 'nan' )
  assertEquals   ( tostring((-nan)^  nan), 'nan' )
  assertEquals   ( tostring(  nan ^ -nan), 'nan' )
  assertEquals   ( tostring((-nan)^ -nan), 'nan' )
end

-- generic complex functions

function TestLuaGmath:testCarg()
  assertEquals( carg(    0) ,  0 )
  assertEquals( carg( tiny) ,  0 )
  assertEquals( carg(  0.1) ,  0 )
  assertEquals( carg(    1) ,  0 )
  assertEquals( carg( huge) ,  0 )
  assertEquals( carg(  inf) ,  0 )
  assertEquals( carg(-   0) ,  0 )
  assertEquals( carg(-tiny) , pi )
  assertEquals( carg(- 0.1) , pi )
  assertEquals( carg(-   1) , pi )
  assertEquals( carg(-huge) , pi )
  assertEquals( carg(- inf) , pi )

  assertEquals( tostring(carg(nan)), 'nan' )
end

function TestLuaGmath:testReal()
  assertEquals( real(    0) ,     0 )
  assertEquals( real( tiny) ,  tiny )
  assertEquals( real(  0.1) ,   0.1 )
  assertEquals( real(    1) ,     1 )
  assertEquals( real( huge) ,  huge )
  assertEquals( real(  inf) ,   inf )
  assertEquals( real(-   0) , -   0 )
  assertEquals( real(-tiny) , -tiny )
  assertEquals( real(- 0.1) , - 0.1 )
  assertEquals( real(-   1) , -   1 )
  assertEquals( real(-huge) , -huge )
  assertEquals( real(- inf) , - inf )

  assertEquals( tostring(real(nan)), 'nan' )
end

function TestLuaGmath:testImag()
  assertEquals( imag(    0) , 0 )
  assertEquals( imag( tiny) , 0 )
  assertEquals( imag(  0.1) , 0 )
  assertEquals( imag(    1) , 0 )
  assertEquals( imag( huge) , 0 )
  assertEquals( imag(  inf) , 0 )
  assertEquals( imag(-   0) , 0 )
  assertEquals( imag(-tiny) , 0 )
  assertEquals( imag(- 0.1) , 0 )
  assertEquals( imag(-   1) , 0 )
  assertEquals( imag(-huge) , 0 )
  assertEquals( imag(- inf) , 0 )
  assertEquals( imag(  nan) , 0 )
end

function TestLuaGmath:testConj()
  assertEquals( conj(    0) ,     0 )
  assertEquals( conj( tiny) ,  tiny )
  assertEquals( conj(  0.1) ,   0.1 )
  assertEquals( conj(    1) ,     1 )
  assertEquals( conj( huge) ,  huge )
  assertEquals( conj(  inf) ,   inf )
  assertEquals( conj(-   0) , -   0 )
  assertEquals( conj(-tiny) , -tiny )
  assertEquals( conj(- 0.1) , - 0.1 )
  assertEquals( conj(-   1) , -   1 )
  assertEquals( conj(-huge) , -huge )
  assertEquals( conj(- inf) , - inf )

  assertEquals( tostring(conj(nan)), 'nan' )
end

function TestLuaGmath:testNorm()
  assertEquals( norm(    0) ,     0 )
  assertEquals( norm( tiny) ,  tiny )
  assertEquals( norm(  0.1) ,   0.1 )
  assertEquals( norm(    1) ,     1 )
  assertEquals( norm( huge) ,  huge )
  assertEquals( norm(  inf) ,   inf )
  assertEquals( norm(-   0) ,     0 )
  assertEquals( norm(-tiny) ,  tiny )
  assertEquals( norm(- 0.1) ,   0.1 )
  assertEquals( norm(-   1) ,     1 )
  assertEquals( norm(-huge) ,  huge )
  assertEquals( norm(- inf) ,   inf )

  assertEquals( tostring(norm(nan)), 'nan' )
end

function TestLuaGmath:testRect()
  assertEquals( rect(    0) ,     0 )
  assertEquals( rect( tiny) ,  tiny )
  assertEquals( rect(  0.1) ,   0.1 )
  assertEquals( rect(    1) ,     1 )
  assertEquals( rect( huge) ,  huge )
  assertEquals( rect(  inf) ,   inf )
  assertEquals( rect(-   0) ,     0 )
  assertEquals( rect(-tiny) ,  tiny )
  assertEquals( rect(- 0.1) ,   0.1 )
  assertEquals( rect(-   1) ,     1 )
  assertEquals( rect(-huge) ,  huge )
  assertEquals( rect(- inf) ,   inf )

  assertEquals( tostring(rect(nan)), 'nan' )
end

function TestLuaGmath:testPolar()
  assertEquals( polar(    0) ,    0 )
  assertEquals( polar( tiny) , tiny )
  assertEquals( polar(  0.1) ,  0.1 )
  assertEquals( polar(    1) ,    1 )
  assertEquals( polar( huge) , huge )
  assertEquals( polar(  inf) ,  inf )
  assertEquals( polar(-   0) ,    0 )
  assertEquals( polar(-tiny) , tiny )
  assertEquals( polar(- 0.1) ,  0.1 )
  assertEquals( polar(-   1) ,    1 )
  assertEquals( polar(-huge) , huge )
  assertEquals( polar(- inf) ,  inf )

  assertEquals( tostring(polar(nan)), 'nan' )
end

-- end ------------------------------------------------------------------------o

/*
 o-----------------------------------------------------------------------------o
 |
 | TPSA functions module implementation
 |
 | Methodical Accelerator Design - Copyright (c) 2016+
 | Support: http://cern.ch/mad  - mad at cern.ch
 | Authors: L. Deniau, laurent.deniau at cern.ch
 |          C. Tomoiaga
 | Contrib: -
 |
 o-----------------------------------------------------------------------------o
 | You can redistribute this file and/or modify it under the terms of the GNU
 | General Public License GPLv3 (or later), as published by the Free Software
 | Foundation. This file is distributed in the hope that it will be useful, but
 | WITHOUT ANY WARRANTY OF ANY KIND. See http://gnu.org/licenses for details.
 o-----------------------------------------------------------------------------o
*/

#include <string.h>
#include <complex.h>
#include <math.h>

#include "mad_log.h"
#include "mad_cst.h"
#include "mad_num.h"
#include "mad_tpsa_impl.h"
#include "mad_ctpsa_impl.h"

#define OLD_SERIES 0 //1
// --- local ------------------------------------------------------------------o

enum { MANUAL_EXPANSION_ORD = 6 };

#ifdef MAD_TPSA_TAYLOR_HORNER

static inline void
fun_taylor (const T *a, T *c, ord_t n, const NUM ord_coef[n+1])
{
  assert(a && c && ord_coef);
  assert(n >= 1); // ord 0 treated outside

  T *acp = GET_TMPX(c);
  FUN(copy)(a,acp);               // copy of a
  FUN(seti)(acp,0,0,0);           // (a-a_0)
  FUN(setval)(c,ord_coef[n]);     // f(a_n)

  // Honer's method (slower by 50% - 100% because mul is always full order)
  while (n-- > 0) {
    FUN(mul)(acp,c,c);            //                    f^(n)(a_n)*(a-a_0)
    FUN(seti)(c,0,1,ord_coef[n]); // f^(n-1)(a_{n-1}) + f^(n)(a_n)*(a-a_0)
  }
  REL_TMPX(acp);
}

#else

static inline void
fun_taylor (const T *a, T *c, ord_t n, const NUM ord_coef[n+1])
{
  assert(a && c && ord_coef);
  assert(n >= 1); // ord 0 treated outside

  T *acp;
  if (n >= 2) acp = GET_TMPX(c), FUN(copy)(a,acp);

  // n=1
  FUN(scl)(a, ord_coef[1], c);
  FUN(seti)(c, 0, 0, ord_coef[0]); // f(a) + f'(a)(a-a0)

  // n=2
  if (n >= 2) {
    T *pow = GET_TMPX(c);
    FUN(seti)(acp,0,0,0);          //  a-a0
    FUN(mul)(acp,acp,pow);         // (a-a0)^2
    FUN(acc)(pow,ord_coef[2],c);   // f(a0) + f'(a0)(a-a0) + f"(a0)(a-a0)^2

    // i=3..n
    if (n >= 3) {
      T *tmp = GET_TMPX(c), *t;

      for (ord_t i = 3; i <= n; ++i) {
        FUN(mul)(acp,pow,tmp);
        FUN(acc)(tmp,ord_coef[i],c); // f(a0) + ... + f^(i)(a0)(a-a0)^i
        SWAP(pow,tmp,t);
      }

      if (n & 1) SWAP(pow,tmp,t); // enforce even number of swaps
      REL_TMPX(tmp);
    }
    REL_TMPX(pow), REL_TMPX(acp);
  }
}
#endif

static inline void
sincos_taylor (const T *a, T *s, T *c,
               ord_t n_s, const NUM sin_coef[n_s+1],
               ord_t n_c, const NUM cos_coef[n_c+1])
{
  assert(a && s && c && sin_coef && cos_coef);
  assert(n_s >= 1 && n_c >= 1);

  ord_t n = MAX(n_s,n_c);
  T *acp = GET_TMPX(c); FUN(copy)(a,acp);

  // n=1
  FUN(scl)(acp, sin_coef[1], s); FUN(seti)(s, 0, 0, sin_coef[0]);
  FUN(scl)(acp, cos_coef[1], c); FUN(seti)(c, 0, 0, cos_coef[0]);

  // n=2
  if (n >= 2) {
    T *pow = GET_TMPX(c);
    FUN(seti)(acp,0,0,0);
    FUN(mul)(acp,acp,pow);
    if (n_s >= 2) FUN(acc)(pow,sin_coef[2],s);
    if (n_c >= 2) FUN(acc)(pow,cos_coef[2],c);

    // i=3..n
    if (n >= 3) {
      T *tmp = GET_TMPX(c), *t;

      for (ord_t i = 3; i <= n; ++i) {
        FUN(mul)(acp,pow,tmp);
        if (n_s >= i) FUN(acc)(tmp,sin_coef[i],s);
        if (n_c >= i) FUN(acc)(tmp,cos_coef[i],c);
        SWAP(pow,tmp,t);
      }

      if (n & 1) SWAP(pow,tmp,t); // enforce even number of swaps
      REL_TMPX(tmp);
    }
    REL_TMPX(pow);
  }
  REL_TMPX(acp);
}

// --- public -----------------------------------------------------------------o

void
FUN(taylor) (const T *a, ssz_t n, const NUM coef[n], T *c)
{
  assert(a && c && coef); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  ensure(n > 0, "invalid number of coefficients (>0 expected)");

  ord_t to = MIN(n-1, c->mo);
  if (!to || FUN(isval)(a)) { FUN(setval)(c,coef[0]); DBGFUN(<-); return; }

  fun_taylor(a,c,to,coef);
  DBGFUN(<-);
}

void
FUN(inv) (const T *a, NUM v, T *c) // c = v/a    // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(a0 != 0, "invalid domain inv("FMT")", VAL(a0));
#ifdef MAD_CTPSA_IMPL
  NUM f0 = mad_cpx_inv(a0);
#else
  NUM f0 = 1/a0;
#endif

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,v*f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  for (ord_t o = 1; o <= to; ++o)
    ord_coef[o] = -ord_coef[o-1] * f0;

  fun_taylor(a,c,to,ord_coef);
  if (v != 1) FUN(scl)(c,v,c);
  DBGFUN(<-);
}

void
FUN(invsqrt) (const T *a, NUM v, T *c) // v/sqrt(a),checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(SELECT(a0 > 0, a0 != 0), "invalid domain invsqrt("FMT")", VAL(a0));
#ifdef MAD_CTPSA_IMPL
  NUM _a0 = mad_cpx_inv(a0);
  NUM  f0 = mad_cpx_inv(sqrt(a0));
#else
  NUM _a0 = 1/a0;
  NUM  f0 = 1/sqrt(a0);
#endif

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,v*f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  for (ord_t o = 1; o <= to; ++o)
    ord_coef[o] = -ord_coef[o-1] * _a0 / (2.0*o) * (2.0*o-1);

  fun_taylor(a,c,to,ord_coef);
  if (v != 1) FUN(scl)(c,v,c);
  DBGFUN(<-);
}

void
FUN(sqrt) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(SELECT(a0 > 0, a0 != 0), "invalid domain sqrt("FMT")", VAL(a0));
  NUM f0 = sqrt(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

#ifdef MAD_CTPSA_IMPL
  NUM _a0 = mad_cpx_inv(a0);
#else
  NUM _a0 = 1/a0;
#endif

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  for (ord_t o = 1; o <= to; ++o)
    ord_coef[o] = -ord_coef[o-1] * _a0 / (2.0*o) * (2.0*o-3);

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(exp) (const T *a, T *c)                      // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = exp(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  for (int o = 1; o <= to; ++o)
    ord_coef[o] = ord_coef[o-1] / o;

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(log) (const T *a, T *c)                      // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(SELECT(a0 > 0, a0 != 0), "invalid domain log("FMT")", VAL(a0));
  NUM f0 = log(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1], _a0 = 1/a0;
  ord_coef[0] = f0;
  ord_coef[1] = _a0;
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = -ord_coef[o-1] * _a0 / o * (o-1);

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(pow) (const T *a, const T *b, T *c)          // checked for real and complex
{
  assert(a && b && c); DBGFUN(->);
  T *t = GET_TMPX(c);
  FUN(log)(a,t);
  FUN(mul)(b,t,c);
  FUN(exp)(c,c);
  REL_TMPX(t); DBGFUN(<-);
}

void
FUN(pown) (const T *a, NUM v, T *c)              // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  T *t = GET_TMPX(c);
  FUN(log)(a,t);
  FUN(scl)(t,v,c);
  FUN(exp)(c,c);
  REL_TMPX(t); DBGFUN(<-);
}

void
FUN(sincos) (const T *a, T *s, T *c)             // checked for real and complex
{
  assert(a && s && c); DBGFUN(->);
  ensure(IS_COMPAT(a,s,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], sa = sin(a0), ca = cos(a0);

  if (a->hi == 0) {
    FUN(setval)(s, sa);
    FUN(setval)(c, ca);
    DBGFUN(<-); return;
  }

  ord_t sto = s->mo, cto = c->mo;
  if (!sto || !cto) {
    if (!sto) FUN(setval)(s, sa);
    else      FUN(sin)(a,s);
    if (!cto) FUN(setval)(c, ca);
    else      FUN(cos)(a,c);
    DBGFUN(<-); return;
  }

  // ord 0, 1
  NUM sin_coef[sto+1], cos_coef[cto+1];
  sin_coef[0] = sa;  cos_coef[0] =  ca;
  sin_coef[1] = ca;  cos_coef[1] = -sa;

  // ords 2..to
  for (ord_t o = 2; o <= sto; ++o )
    sin_coef[o] = -sin_coef[o-2] / (o*(o-1));
  for (ord_t o = 2; o <= cto; ++o )
    cos_coef[o] = -cos_coef[o-2] / (o*(o-1));

  sincos_taylor(a,s,c, sto,sin_coef, cto,cos_coef);
  DBGFUN(<-);
}

void
FUN(sin) (const T *a, T *c)                      // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = sin(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  ord_coef[1] = cos(a0);
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = -ord_coef[o-2] / (o*(o-1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(cos) (const T *a, T *c)                      // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = cos(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  ord_coef[1] = -sin(a0);
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = -ord_coef[o-2] / (o*(o-1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(tan) (const T *a, T *c)                      // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(cos(a0) != 0, "invalid domain tan("FMT")", VAL(a0));
  NUM f0 = tan(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) {
    T *t = GET_TMPX(c);
    FUN(sincos)(a,t,c);
    FUN(div)(t,c,c);
    REL_TMPX(t); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], f2 = f0*f0;
  switch(to) {
  case 6: ord_coef[6] = f0*(17./45 + f2*(77./45 + f2*(7./3 + f2))); /* FALLTHRU */
  case 5: ord_coef[5] = 2./15 + f2*(17./15 + f2*(2 + f2));          /* FALLTHRU */
  case 4: ord_coef[4] = f0*(2./3 + f2*(5./3 + f2));                 /* FALLTHRU */
  case 3: ord_coef[3] = 1./3 + f2*(4./3 + f2);                      /* FALLTHRU */
  case 2: ord_coef[2] = f0*(1 + f2);                                /* FALLTHRU */
  case 1: ord_coef[1] = 1 + f2;                                     /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                         break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(cot) (const T *a, T *c)                      // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(sin(a0) != 0, "invalid domain cot("FMT")", VAL(a0));
  NUM f0 = tan(M_PI_2 - a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  T *t = GET_TMPX(c);
  FUN(sincos)(a,t,c);
  FUN(div)(c,t,c);
  REL_TMPX(t); DBGFUN(<-); return;

#if 0
  // Inaccurate expansion for small a0, need some work...
  NUM ord_coef[to+1], f2 = f0*f0;
  switch(to) {
  case 6: ord_coef[6] = f0*(17./45 + f2*(77./45 + f2*(7./3 + f2))); /* FALLTHRU */
  case 5: ord_coef[5] = -2./15 - f2*(17./15 + f2*(2 + f2));         /* FALLTHRU */
  case 4: ord_coef[4] = f0*(2./3 + f2*(5./3 + f2));                 /* FALLTHRU */
  case 3: ord_coef[3] = -1./3 - f2*(4./3 + f2);                     /* FALLTHRU */
  case 2: ord_coef[2] = f0*(1 + f2);                                /* FALLTHRU */
  case 1: ord_coef[1] = -1 - f2;                                    /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                         break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
#endif
}

void
FUN(sinc) (const T *a, T *c)
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");

  NUM a0 = a->coef[0];
  ord_t to = c->mo;

  if (!to || FUN(isval)(a)) {
#ifdef MAD_CTPSA_IMPL
    NUM f0 = mad_cpx_sinc(a0);
#else
    NUM f0 = mad_num_sinc (a0);
#endif
    FUN(setval)(c,f0); DBGFUN(<-); return;
  }
  NUM ord_coef[to+1];
  if (fabs(a0) > 0.5) { // sin(x)/x
    T *t = GET_TMPX(c);
    FUN(sin)(a,t);
    FUN(div)(t,a,c);
    REL_TMPX(t); DBGFUN(<-); return;
  }

  if (fabs(a0) > 1e-12) { 

   NUM fact = 1;
   NUM sa = sin(a0), _a0 = 1/a0, f1;
   NUM odd_coef[6], even_coef[6], scalar = -1;
   NUM a2 = pow(a0,2), a3 = pow(a0,3), a4 = pow(a0,4), a5 = pow(a0,5), a6 = pow(a0,6), a7 = pow(a0,7), 
   a8 = pow(a0,8), a9 = pow(a0,9), a10 = pow(a0,10), a11 = pow(a0,11), a12 = pow(a0,12), a13 = pow(a0,13);


   odd_coef[0] = 30, odd_coef[1] = -840, odd_coef[2] = 45360,
   odd_coef[3] = -3991680, odd_coef[4] = 518918400, odd_coef[5] = -93405312000;

   even_coef[0] = 10, even_coef[1] = -168, even_coef[2] = 6480,
   even_coef[3] = -443520, even_coef[4] = 47174400, even_coef[5] = -7185024000;

   for (int o = 1; o <= to; o+=2) {
     fact *= ((o)*(o+1)); 
     odd_coef[0]  = ((o>1)*mad_num_sign(odd_coef[0])*12          + odd_coef[0]);
     odd_coef[1]  = ((o>1)*mad_num_sign(odd_coef[1])*240         + odd_coef[1]);
     odd_coef[2]  = ((o>1)*mad_num_sign(odd_coef[2])*1080        + odd_coef[2]);
     odd_coef[3]  = ((o>1)*mad_num_sign(odd_coef[3])*725760      + odd_coef[3]);
     odd_coef[4]  = ((o>1)*mad_num_sign(odd_coef[4])*79833600    + odd_coef[4]);
     odd_coef[5]  = ((o>1)*mad_num_sign(odd_coef[5])*12454041600 + odd_coef[5]);

     even_coef[0] = ((o>1)*mad_num_sign(even_coef[0])*4          + even_coef[0]);
     even_coef[1] = ((o>1)*mad_num_sign(even_coef[1])*48         + even_coef[1]);
     even_coef[2] = ((o>1)*mad_num_sign(even_coef[2])*1440       + even_coef[2]);
     even_coef[3] = ((o>1)*mad_num_sign(even_coef[3])*80640      + even_coef[3]);
     even_coef[4] = ((o>1)*mad_num_sign(even_coef[4])*7257600    + even_coef[4]);
     even_coef[5] = ((o>1)*mad_num_sign(even_coef[5])*958003200  + even_coef[5]);

     scalar  = (mad_num_sign(scalar)*2 + scalar);

     ord_coef[(o)       ] = (pow(-1,o/2)*(1./scalar*a0 + 1./ odd_coef[0]*a3 + 1./ odd_coef[1]*a5 + 1./ odd_coef[2]*a7 + 1./ odd_coef[3]*a9 + 1./ odd_coef[4]*a11 + 1./ odd_coef[5]*a13))*((o+1)/fact);
     ord_coef[(o+1)%(to+1)] = (pow(-1,o/2)*(1./scalar    + 1./even_coef[0]*a2 + 1./even_coef[1]*a4 + 1./even_coef[2]*a6 + 1./even_coef[3]*a8 + 1./even_coef[4]*a10 + 1./even_coef[5]*a12))/(      fact);
   }

   num_t f0 = sa*_a0;
   ord_coef[0] = f0;
   //ord_coef[15] = (1./scalar    + 1./even_coef[0]*a2 + 1./even_coef[1]*a4 + 1./even_coef[2]*a6 + 1./even_coef[3]*a8 + 1./even_coef[4]*a10 + 1./even_coef[5]*a12)/(      fact);
   fun_taylor(a,c,to,ord_coef); return;
  }
  // sinc(x) at x=0
  //NUM ord_coef[to+1];
  ord_coef[0] = 1;
  ord_coef[1] = 0;
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = -ord_coef[o-2] / (o * (o+1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(sincosh) (const T *a, T *sh, T *ch)          // checked for real and complex
{
  assert(a && sh && ch); DBGFUN(->);
  ensure(IS_COMPAT(a,sh,ch), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], sa = sinh(a0), ca = cosh(a0);

  if (a->hi == 0) {
    FUN(setval)(sh, sa);
    FUN(setval)(ch, ca);
    DBGFUN(<-); return;
  }

  ord_t sto = sh->mo, cto = ch->mo;
  if (!sto || !cto) {
    if (!sto) FUN(setval)(sh, sa);
    else      FUN(sinh)(a,sh);
    if (!cto) FUN(setval)(ch, ca);
    else      FUN(cosh)(a,ch);
    DBGFUN(<-); return;
  }

  // ord 0, 1
  NUM sin_coef[sto+1], cos_coef[cto+1];
  sin_coef[0] = sa;  cos_coef[0] = ca;
  sin_coef[1] = ca;  cos_coef[1] = sa;

  // ords 2..to
  for (int o = 2; o <= sto; ++o )
    sin_coef[o] = sin_coef[o-2] / (o*(o-1));
  for (int o = 2; o <= cto; ++o )
    cos_coef[o] = cos_coef[o-2] / (o*(o-1));

  sincos_taylor(a,sh,ch, sto,sin_coef, cto,cos_coef);
  DBGFUN(<-);
}

void
FUN(sinh) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = sinh(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  ord_coef[1] = cosh(a0);
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = ord_coef[o-2] / (o*(o-1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(cosh) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = cosh(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1];
  ord_coef[0] = f0;
  ord_coef[1] = sinh(a0);
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = ord_coef[o-2] / (o*(o-1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(tanh) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = tanh(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) {
    T *t = GET_TMPX(c);
    FUN(sincosh)(a,t,c);
    FUN(div)(t,c,c);
    REL_TMPX(t); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], f2 = f0*f0;
  switch(to) {
  case 6: ord_coef[6] = f0*(-17./45 + f2*(77./45 + f2*(-7./3 + f2))); /* FALLTHRU */
  case 5: ord_coef[5] = 2./15 + f2*(-17./15 + f2*(2 - f2));           /* FALLTHRU */
  case 4: ord_coef[4] = f0*(2./3 + f2*(-5./3 + f2));                  /* FALLTHRU */
  case 3: ord_coef[3] = -1./3 + f2*(4./3 - f2);                       /* FALLTHRU */
  case 2: ord_coef[2] = f0*(-1 + f2);                                 /* FALLTHRU */
  case 1: ord_coef[1] = 1 - f2;                                       /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                           break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(coth) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = tanh(a0);
  ensure(f0 != 0, "invalid domain coth("FMT")", VAL(a0));
#ifdef MAD_CTPSA_IMPL
  f0 = mad_cpx_inv(f0);
#else
  f0 = 1/f0;
#endif

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) {
    T *t = GET_TMPX(c);
    FUN(sincosh)(a,t,c);
    FUN(div)(c,t,c);
    REL_TMPX(t); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], f2 = f0*f0;
  switch(to) {
  case 6: ord_coef[6] = f0*(-17./45 + f2*(77./45 + f2*(-7./3 + f2))); /* FALLTHRU */
  case 5: ord_coef[5] = 2./15 + f2*(-17./15 + f2*(2 - f2));           /* FALLTHRU */
  case 4: ord_coef[4] = f0*(2./3 + f2*(-5./3 + f2));                  /* FALLTHRU */
  case 3: ord_coef[3] = -1./3 + f2*(4./3 - f2);                       /* FALLTHRU */
  case 2: ord_coef[2] = f0*(-1 + f2);                                 /* FALLTHRU */
  case 1: ord_coef[1] = 1 - f2;                                       /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                           break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(sinhc) (const T *a, T *c)
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");

  NUM a0 = a->coef[0];
  ord_t to = c->mo;

  if (!to || FUN(isval)(a)) {
#ifdef MAD_CTPSA_IMPL
    NUM f0 = mad_cpx_sinhc(a0);
#else
    NUM f0 = mad_num_sinhc (a0);
#endif
    FUN(setval)(c,f0); DBGFUN(<-); return;
  }

  if (fabs(a0) > 0.5) { // sinh(x)/x
    T *t = GET_TMPX(c);
    FUN(sinh)(a,t);
    FUN(div)(t,a,c);
    REL_TMPX(t); DBGFUN(<-); return;
  }

NUM ord_coef[to+1];
if (fabs(a0) > 1e-12) { 

   NUM fact = 1;
   NUM sa = sinh(a0), _a0 = 1/a0, f1;
   NUM odd_coef[6], even_coef[6], scalar = 1;
   NUM a2 = pow(a0,2), a3 = pow(a0,3), a4 = pow(a0,4), a5 = pow(a0,5), a6 = pow(a0,6), a7 = pow(a0,7), 
   a8 = pow(a0,8), a9 = pow(a0,9), a10 = pow(a0,10), a11 = pow(a0,11), a12 = pow(a0,12), a13 = pow(a0,13);


   odd_coef[0] = 30, odd_coef[1] = 840, odd_coef[2] = 45360,
   odd_coef[3] = 3991680, odd_coef[4] = 518918400, odd_coef[5] = 93405312000;

   even_coef[0] = 10, even_coef[1] = 168, even_coef[2] = 6480,
   even_coef[3] = 443520, even_coef[4] = 47174400, even_coef[5] = 7185024000;

   for (int o = 1; o <= to; o+=2) {
     fact *= ((o)*(o+1)); 
     odd_coef[0]  = ((o>1)*12          + odd_coef[0]);
     odd_coef[1]  = ((o>1)*240         + odd_coef[1]);
     odd_coef[2]  = ((o>1)*1080        + odd_coef[2]);
     odd_coef[3]  = ((o>1)*725760      + odd_coef[3]);
     odd_coef[4]  = ((o>1)*79833600    + odd_coef[4]);
     odd_coef[5]  = ((o>1)*12454041600 + odd_coef[5]);

     even_coef[0] = ((o>1)*4          + even_coef[0]);
     even_coef[1] = ((o>1)*48         + even_coef[1]);
     even_coef[2] = ((o>1)*1440       + even_coef[2]);
     even_coef[3] = ((o>1)*80640      + even_coef[3]);
     even_coef[4] = ((o>1)*7257600    + even_coef[4]);
     even_coef[5] = ((o>1)*958003200  + even_coef[5]);

     scalar  = (mad_num_sign(scalar)*2 + scalar);

     ord_coef[(o)       ] = ((1./scalar*a0 + 1./ odd_coef[0]*a3 + 1./ odd_coef[1]*a5 + 1./ odd_coef[2]*a7 + 1./ odd_coef[3]*a9 + 1./ odd_coef[4]*a11 + 1./ odd_coef[5]*a13))*((o+1)/fact);
     ord_coef[(o+1)%(to+1)] = ((1./scalar    + 1./even_coef[0]*a2 + 1./even_coef[1]*a4 + 1./even_coef[2]*a6 + 1./even_coef[3]*a8 + 1./even_coef[4]*a10 + 1./even_coef[5]*a12))/(      fact);
   }

   num_t f0 = sa*_a0;
   ord_coef[0] = f0;
   //ord_coef[15] = (1./scalar    + 1./even_coef[0]*a2 + 1./even_coef[1]*a4 + 1./even_coef[2]*a6 + 1./even_coef[3]*a8 + 1./even_coef[4]*a10 + 1./even_coef[5]*a12)/(      fact);
   fun_taylor(a,c,to,ord_coef); return;
  }

  // sinhc(x) at x=0
  ord_coef[0] = 1;
  ord_coef[1] = 0;
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = ord_coef[o-2] / (o * (o+1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(asin) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(SELECT(fabs(a0) < 1, 1), "invalid domain asin("FMT")", VAL(a0));
  NUM f0 = asin(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) { // use simpler and faster approach?
    // asin(x) = -i*ln(i*x + sqrt(1-x^2))
#ifdef MAD_CTPSA_IMPL
    mad_ctpsa_logaxpsqrtbpcx2(a, I, 1, -1, c);
    mad_ctpsa_scl(c, -I, c);
#else
    ctpsa_t *t = GET_TMPC(c);
    mad_ctpsa_cplx(a, NULL, t);
    mad_ctpsa_logaxpsqrtbpcx2(t, I, 1, -1, t);
    mad_ctpsa_scl(t, -I, t);
    mad_ctpsa_real(t, c);
    REL_TMPC(t);
#endif
    DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = 1/sqrt(1-a2), f2 = f1*f1, f4 = f2*f2;
  switch(to) {
  case 6: ord_coef[6] = a0*(5./16 + a2*(5./6 + 1./6*a2)) *f4*f4*f2*f1; /* FALLTHRU */
  case 5: ord_coef[5] = (3./40 + a2*(3./5 + 1./5*a2)) *f4*f4*f1;       /* FALLTHRU */
  case 4: ord_coef[4] = a0*(3./8 + 1./4*a2) *f4*f2*f1;                 /* FALLTHRU */
  case 3: ord_coef[3] = (1./6 + 1./3*a2) *f4*f1;                       /* FALLTHRU */
  case 2: ord_coef[2] = a0*(1./2) *f2*f1;                              /* FALLTHRU */
  case 1: ord_coef[1] = f1;                                            /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                            break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(acos) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(SELECT(fabs(a0) < 1, 1), "invalid domain acos("FMT")", VAL(a0));
  NUM f0 = acos(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) {  // use simpler and faster approach?
    // acos(x) = -i*ln(x+i*sqrt(1-x^2)) = -asin(x)+pi/2
#ifdef MAD_CTPSA_IMPL
    mad_ctpsa_logaxpsqrtbpcx2(a, I, 1, -1, c);
    mad_ctpsa_axpb(I, c, M_PI_2, c);
#else
    ctpsa_t *t = GET_TMPC(c);
    mad_ctpsa_cplx(a, NULL, t);
    mad_ctpsa_logaxpsqrtbpcx2(t, I, 1, -1, t);
    mad_ctpsa_axpb(I, t, M_PI_2, t);
    mad_ctpsa_real(t, c);
    REL_TMPC(t);
#endif
    DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = -1/sqrt(1-a2), f2 = f1*f1, f4 = f2*f2;
  switch(to) {
  case 6: ord_coef[6] = a0*(5./16 + a2*(5./6 + 1./6*a2)) *f4*f4*f2*f1; /* FALLTHRU */
  case 5: ord_coef[5] = (3./40 + a2*(3./5 + 1./5*a2)) *f4*f4*f1;       /* FALLTHRU */
  case 4: ord_coef[4] = a0*(3./8 + 1./4*a2) *f4*f2*f1;                 /* FALLTHRU */
  case 3: ord_coef[3] = (1./6 + 1./3*a2) *f4*f1;                       /* FALLTHRU */
  case 2: ord_coef[2] = a0*(1./2) *f2*f1;                              /* FALLTHRU */
  case 1: ord_coef[1] = f1;                                            /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                            break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(atan) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = atan(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) { // use simpler and faster approach?
    // atan(x) = i/2 ln((i+x) / (i-x))
#ifdef MAD_CTPSA_IMPL
    ctpsa_t *tn = GET_TMPX(c), *td = GET_TMPX(c);
    mad_ctpsa_copy(a, tn);
    mad_ctpsa_axpb(-1, tn, I, td);
    mad_ctpsa_seti(tn, 0, 1, I);
    mad_ctpsa_logxdy(tn, td, c);
    mad_ctpsa_scl(c, I/2, c);
#else
    ctpsa_t *tn = GET_TMPC(c), *td = GET_TMPC(c);
    mad_ctpsa_cplx(a, NULL, tn);
    mad_ctpsa_axpb(-1, tn, I, td);
    mad_ctpsa_seti(tn, 0, 1, I);
    mad_ctpsa_logxdy(tn, td, tn);
    mad_ctpsa_scl(tn, I/2, tn);
    mad_ctpsa_real(tn, c);
#endif
    REL_TMPC(td), REL_TMPC(tn); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = 1/(1+a2), f2 = f1*f1, f4 = f2*f2;
  switch(to) {
  case 6: ord_coef[6] = -a0*(1 + a2*(-10./3 + a2)) *f4*f2; /* FALLTHRU */
  case 5: ord_coef[5] = (1./5 + a2*(-2 + a2)) *f4*f1;      /* FALLTHRU */
  case 4: ord_coef[4] = -a0*(-1 + a2) *f4;                 /* FALLTHRU */
  case 3: ord_coef[3] = (-1./3 + a2) *f2*f1;               /* FALLTHRU */
  case 2: ord_coef[2] = -a0 *f2;                           /* FALLTHRU */
  case 1: ord_coef[1] = f1;                                /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(acot) (const T *a, T *c)                     // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(a0 != 0, "invalid domain acot("FMT")", VAL(a0));
#ifdef MAD_CTPSA_IMPL
  NUM f0 = atan(mad_cpx_inv(a0));
#else
  NUM f0 = atan(1/a0);
#endif

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) { // use simpler and faster approach?
    // acot(x) = i/2 ln((x-i) / (x+i))
#ifdef MAD_CTPSA_IMPL
    ctpsa_t *tn = GET_TMPX(c), *td = GET_TMPX(c);
    mad_ctpsa_copy( a, tn);
    mad_ctpsa_copy(tn, td);
    mad_ctpsa_seti(tn, 0, 1, -I);
    mad_ctpsa_seti(td, 0, 1,  I);
    mad_ctpsa_logxdy(tn, td, c);
    mad_ctpsa_scl(c, I/2, c);
#else
    ctpsa_t *tn = GET_TMPC(c), *td = GET_TMPC(c);
    mad_ctpsa_cplx(a, NULL, tn);
    mad_ctpsa_copy(tn, td);
    mad_ctpsa_seti(tn, 0, 1, -I);
    mad_ctpsa_seti(td, 0, 1,  I);
    mad_ctpsa_logxdy(tn, td, tn);
    mad_ctpsa_scl(tn, I/2, tn);
    mad_ctpsa_real(tn, c);
#endif
    REL_TMPC(td), REL_TMPC(tn); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = -1/(1+a2), f2 = f1*f1, f4 = f2*f2;
  switch(to) {
  case 6: ord_coef[6] = a0*(1 + a2*(-10./3 + a2)) *f4*f2; /* FALLTHRU */
  case 5: ord_coef[5] = (1./5 + a2*(-2 + a2)) *f4*f1;     /* FALLTHRU */
  case 4: ord_coef[4] = a0*(-1 + a2) *f4;                 /* FALLTHRU */
  case 3: ord_coef[3] = (-1./3 + a2) *f2*f1;              /* FALLTHRU */
  case 2: ord_coef[2] = a0 *f2;                           /* FALLTHRU */
  case 1: ord_coef[1] = f1;                               /* FALLTHRU */
  case 0: ord_coef[0] = f0;                               break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(asinc) (const T *a, T *c)
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");

  NUM a0 = a->coef[0];
  ord_t to = c->mo;

  if (!to || FUN(isval)(a)) {
#ifdef MAD_CTPSA_IMPL
    NUM f0 = mad_cpx_asinc(a0);
#else
    NUM f0 = mad_num_asinc(a0);
#endif
    FUN(setval)(c,f0); DBGFUN(<-); return;
  }

  if (fabs(a0) > 0.42) { // asin(x)/x
    T *t = GET_TMPX(c);
    FUN(asin)(a,t);
    FUN(div)(t,a,c);
    REL_TMPX(t); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1];

  if (fabs(a0) > 1e-12) { 
    for (int i = 0; i <= to; ++i)
      ord_coef[i] = 0;

    int ord = 30;//one can specify according to the accuracy requests
    NUM mult=1, fact=1;
    NUM temp_coef[ord+1];

    temp_coef[0] = 1./3;
    for (int i = 1; i <= ord; ++i)
    temp_coef[i] = temp_coef[i-1]*SQR(2*i + 1)/(i*(4*i + 6));

    for (int o = 1; o <= to; o+=2){
      fact *= (o*(o+1));
      for (int i = 0; i <= ord; ++i){

          mult = (o!=1) ? pow(2*i + o, 3)/(2*i + o + 2) : 1 ;
          temp_coef[i           ] *= mult; 

          ord_coef [o           ] += (pow(a0,i)*temp_coef[i])*pow(a0,i+1)*(o+1  )/fact;
          ord_coef [(o+1)%(to+1)] += (pow(a0,i)*temp_coef[i])*pow(a0,i  )*(2*i+1)/fact;

      }
    }

  ord_coef[0] = mad_num_asinc(a0);
  fun_taylor(a,c,to,ord_coef);
  return;
  }
  
  // asinc(x) at x=0
  ord_coef[0] = 1;
  ord_coef[1] = 0;
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = (ord_coef[o-2] * SQR(o-1)) / (o * (o+1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(asinh) (const T *a, T *c)                    // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0], f0 = asinh(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) { // use simpler and faster approach?
    // asinh(x) = log(x + sqrt(x^2+1))
    FUN(logaxpsqrtbpcx2)(a, 1, 1, 1, c);
    DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = 1/sqrt(a2+1), f2 = f1*f1, f4 = f2*f2;
  switch(to) {
  case 6: ord_coef[6] = a0*(-5./16 + a2*(5./6 - 1./6*a2)) *f4*f4*f2*f1; /* FALLTHRU */
  case 5: ord_coef[5] = (3./40 + a2*(-3./5 + 1./5*a2)) *f4*f4*f1;       /* FALLTHRU */
  case 4: ord_coef[4] = a0*(3./8 - 1./4*a2) *f4*f2*f1;                  /* FALLTHRU */
  case 3: ord_coef[3] = (-1./6 + 1./3*a2) *f4*f1;                       /* FALLTHRU */
  case 2: ord_coef[2] = a0*(-1./2) *f2*f1;                              /* FALLTHRU */
  case 1: ord_coef[1] = f1;                                             /* FALLTHRU */
  case 0: ord_coef[0] = f0;                                             break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}


void
FUN(acosh) (const T *a, T *c)                    // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(SELECT(a0 > 1, 1), "invalid domain acosh("FMT")", VAL(a0));
  NUM f0 = acosh(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  #if OLD_SERIES
    if (to > MANUAL_EXPANSION_ORD) { // use simpler and faster approach?
      // acosh(x) = ln(x + sqrt(x^2-1))
      FUN(logaxpsqrtbpcx2)(a, 1, -1, 1, c);
      DBGFUN(<-); return;
    }

    NUM ord_coef[to+1], a2 = a0*a0, f1 = 1/sqrt(a2-1), f2 = f1*f1, f4 = f2*f2;
    switch(to) {
    case 6: ord_coef[6] = -a0*(5./16 + a2*(5./6 + 1./6*a2)) *f4*f4*f2*f1; /* FALLTHRU */
    case 5: ord_coef[5] = (3./40 + a2*(3./5 + 1./5*a2)) *f4*f4*f1;        /* FALLTHRU */
    case 4: ord_coef[4] = -a0*(3./8 + 1./4*a2) *f4*f2*f1;                 /* FALLTHRU */
    case 3: ord_coef[3] = (1./6 + 1./3*a2) *f4*f1;                        /* FALLTHRU */
    case 2: ord_coef[2] = -a0*(1./2) *f2*f1;                              /* FALLTHRU */
    case 1: ord_coef[1] = f1;                                             /* FALLTHRU */
    case 0: ord_coef[0] = f0;                                             break;
    assert(!"unexpected missing coefficients");
    }
    
  #else
    NUM ord_coef[to+1]           ;
    num_t asqrt = sqrt(a0*a0 - 1);
    num_t aplus =  1./(a0    + 1);
    num_t  amin =  1./(a0    - 1);
    num_t denom =         (asqrt);
    num_t numer =               0;
    num_t  fact = 1              ;
    int   delta, trsh            ;
    ord_coef[0] =    f0;
    ord_coef[1] = 1./denom;
    for (int ord = 2; ord <= to; ord++ ){
      fact  *= ord;
      denom *= -2;
     
      trsh = floor((ord-1)/2);
      numer = 0;
      for (int i= 0; i <= trsh; i++){
        delta = (ord-1-2*i ==0) ? 2 : 1;
        numer += mad_num_dfact(2*ord - 3 -2*i)*mad_num_HypTri(i,ord-i)*mad_num_dfact(2*i-1)*(pow(aplus,ord-i-1)*pow(amin,i) + pow(amin,ord-i-1)*pow(aplus,i))/delta;
        printf("%f  \n",denom);
      }  
      printf("\n");
      //printf("\n %f \n", numer/denom);
      ord_coef[ord] = numer/denom/fact;
    }
  #endif

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(atanh) (const T *a, T *c)                    // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(fabs(a0) SELECT(< 1, != 1), "invalid domain atanh("FMT")", VAL(a0));
  NUM f0 = atanh(a0);

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) { // use simpler and faster approach?
    // atanh(x) = 1/2 ln((1+x) / (1-x))
    T *tn = GET_TMPX(c), *td = GET_TMPX(c);
    FUN(copy)(a, tn);
    FUN(seti)(tn, 0, 1, 1);
    FUN(axpb)(-1, a, 1, td);
    FUN(logxdy)(tn, td, c);
    FUN(scl)(c, 0.5, c);
    REL_TMPX(td), REL_TMPX(tn); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = 1/(1-a2), f2 = f1*f1, f4 = f2*f2;
  switch(to) {
  case 6: ord_coef[6] = a0*(1 + a2*(10./3 + a2)) *f4*f2; /* FALLTHRU */
  case 5: ord_coef[5] = (1./5 + a2*(2 + a2)) *f4*f1;     /* FALLTHRU */
  case 4: ord_coef[4] = a0*(1 + a2) *f4;                 /* FALLTHRU */
  case 3: ord_coef[3] = (1./3 + a2) *f2*f1;              /* FALLTHRU */
  case 2: ord_coef[2] = a0 *f2;                          /* FALLTHRU */
  case 1: ord_coef[1] = f1;                              /* FALLTHRU */
  case 0: ord_coef[0] = f0;                              break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(acoth) (const T *a, T *c)                    // checked for real and complex
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");
  NUM a0 = a->coef[0];
  ensure(fabs(a0) SELECT(> 1, != 1 && a0 != 0), "invalid domain acoth("FMT")", VAL(a0));
#ifdef MAD_CTPSA_IMPL
  NUM f0 = atanh(mad_cpx_inv(a0));
#else
  NUM f0 = atanh(1/a0);
#endif

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  if (to > MANUAL_EXPANSION_ORD) { // use simpler and faster approach?
    // acoth(x) = 1/2 ln((x+1) / (x-1))
    T *tn = GET_TMPX(c), *td = GET_TMPX(c);
    FUN(copy)(a, tn);
    FUN(seti)(tn, 0, 1, 1);
    FUN(copy)(a, td);
    FUN(seti)(td, 0, 1, -1);
    FUN(logxdy)(tn, td, c);
    FUN(scl)(c, 0.5, c);
    REL_TMPX(td), REL_TMPX(tn); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = 1/(1-a2), f2 = f1*f1, f4 = f2*f2;
  switch(to) {
  case 6: ord_coef[6] = a0*(1 + a2*(10./3 + a2)) *f4*f2; /* FALLTHRU */
  case 5: ord_coef[5] = (1./5 + a2*(2 + a2)) *f4*f1;     /* FALLTHRU */
  case 4: ord_coef[4] = a0*(1 + a2) *f4;                 /* FALLTHRU */
  case 3: ord_coef[3] = (1./3 + a2) *f2*f1;              /* FALLTHRU */
  case 2: ord_coef[2] = a0 *f2;                          /* FALLTHRU */
  case 1: ord_coef[1] = f1;                              /* FALLTHRU */
  case 0: ord_coef[0] = f0;                              break;
  assert(!"unexpected missing coefficients");
  }

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(asinhc) (const T *a, T *c)
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");

  NUM a0 = a->coef[0];
  ord_t to = c->mo;

  if (!to || FUN(isval)(a)) {
#ifdef MAD_CTPSA_IMPL
    NUM f0 = mad_cpx_asinhc(a0);
#else
    NUM f0 = mad_num_asinhc (a0);
#endif
    FUN(setval)(c,f0); DBGFUN(<-); return;
  }

  if (fabs(a0) > 0.42) { // asin(x)/x
    T *t = GET_TMPX(c);
    FUN(asinh)(a,t);
    FUN(div)(t,a,c);
    REL_TMPX(t); DBGFUN(<-); return;
  }

  NUM ord_coef[to+1];

  if (fabs(a0) > 1e-12) { 
    for (int i = 0; i <= to; ++i)
      ord_coef[i] = 0;
    int ord = 30;
    NUM mult=1, fact=1;
    NUM temp_coef[ord+1];

    temp_coef[0] = -1./3;
    for (int i = 1; i <= ord; ++i)
    temp_coef[i] = -temp_coef[i-1]*SQR(2*i + 1)/(i*(4*i + 6));

    for (int o = 1; o <= to; o+=2){
      fact *= (o*(o+1));
      for (int i = 0; i <= ord; ++i){

          mult = (o!=1) ? -pow(2*i + o, 3)/(2*i + o + 2) : 1 ;
          temp_coef[i           ] *= mult; 

          ord_coef [o           ] += (pow(a0,i)*temp_coef[i])*pow(a0,i+1)*(o+1  )/fact        ;
          ord_coef [(o+1)%(to+1)] += (pow(a0,i)*temp_coef[i])*pow(a0,i  )*(2*i+1)/fact;

      }
    }

  ord_coef[0] = mad_num_asinhc(a0);
  fun_taylor(a,c,to,ord_coef);
  return;
  }

  // asinhc(x) at x=0
  ord_coef[0] = 1;
  ord_coef[1] = 0;
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = -(ord_coef[o-2] * SQR(o-1)) / (o * (o+1));

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(erf) (const T *a, T *c)
{
  assert(a && c); DBGFUN(->);
  ensure(IS_COMPAT(a,c), "incompatibles GTPSA (descriptors differ)");

  // erf(z) = 2/sqrt(pi) \int_0^z exp(-t^2) dt
  NUM a0 = a->coef[0];
#ifdef MAD_CTPSA_IMPL
  NUM f0 = mad_cpx_erf(a0, 0);
#else
  NUM f0 = mad_num_erf (a0);
#endif

  ord_t to = c->mo;
  if (!to || FUN(isval)(a)) { FUN(setval)(c,f0); DBGFUN(<-); return; }

  NUM ord_coef[to+1], a2 = a0*a0, f1 = M_2_SQRTPI*exp(-a2);
  ord_coef[0] = f0;
  ord_coef[1] = f1;
  for (int o = 2; o <= to; ++o)
    ord_coef[o] = -2*((o-2)*ord_coef[o-2]/(o-1) + ord_coef[o-1]*a0) / o;

  fun_taylor(a,c,to,ord_coef);
  DBGFUN(<-);
}

void
FUN(erfc) (const T *a, T *c)
{
  assert(a && c); DBGFUN(->);
  FUN(erf)(a,c);
  FUN(axpb)(-1,c,1,c);
  DBGFUN(<-);
}

// --- without complex-by-value version ---------------------------------------o

#ifdef MAD_CTPSA_IMPL

void FUN(inv_r) (const T *a, num_t v_re, num_t v_im, T *c)
{ FUN(inv)(a, CPX(v), c); }

void FUN(invsqrt_r) (const T *a, num_t v_re, num_t v_im, T *c)
{ FUN(invsqrt)(a, CPX(v), c); }

void FUN(pown_r) (const T *a, num_t v_re, num_t v_im, T *c)
{ FUN(pown)(a, CPX(v), c); }

#endif

// --- end --------------------------------------------------------------------o

/*
Recurrence of Taylor coefficients:
----------------------------------
(f(g(x)))'   = f'(g(x)).g'(x)
(f(x).g(x))' = f'(x)g(x) + f(x)g'(x)

-- sinc(z) -----
[0]  sinc(z)      =   sin(z)/z ; cos(z)/z = [c] ; sin(z) = sz ; cos(z) = cz
[1] (sinc(z))'    =  cz/z -1sz/z^2                                                     =  [c]-1*[0]/z
[2] (sinc(z))''   = -sz/z -2cz/z^2 +2!sz/z^3                                           = -[0]-2*[1]/z
[3] (sinc(z))'''  = -cz/z +3sz/z^2 +3!cz/z^3 - 3!sz/z^4                                = -[c]-3*[2]/z
[4] (sinc(z))^(4) =  sz/z +4cz/z^2 -12sz/z^3 - 4!cz/z^4 + 4!sz/z^5                     =  [0]-4*[3]/z
[5] (sinc(z))^(5) =  cz/z -5sz/z^2 -20cz/z^3 + 60sz/z^4 + 5!cz/z^5 -5!sz/z^6           =  [c]-5*[4]/z
[6] (sinc(z))^(6) = -sz/z -6cz/z^2 +30sz/z^3 +120cz/z^4 -360sz/z^5 -6!cz/z^6 +6!sz/z^7 = -[0]-6*[5]/z

-- erf(z) -----
[0]  erf(z)
[1] (erf(z))'    =     1
[2] (erf(z))''   = -2*      z                                 = -2*(0*[0]+[1]*z)
[3] (erf(z))'''  = -2*(1 -2*z^2)                              = -2*(1*[1]+[2]*z)
[4] (erf(z))^(4) = -2*(-4*z -2*(1-2*z^2)*z)                   = -2*(2*[2]+[3]*z)
[5] (erf(z))^(5) = -2*(-6*(1-2*z^2) +4*(3*z-2*z^3)*z)         = -2*(3*[3]+[4]*z)
[6] (erf(z))^(6) = -2*(16*(3*z-2*z^3) +4*(3-12*z^2+4*z^4)*z)  = -2*(4*[4]+[5]*z)
                   % *exp(-z^2) *2/sqrt(pi)
{0} = 0
{1} = 1 *exp(-z^2)
(exp(-z^2))'
    = exp'(-z^2).(-z^2)'
{2} = -2*z *exp(-z^2)                                         = -2*(0*{0}+{1}*z)
-2*(z*exp(-z^2))'
    = -2*(z'*exp(-z^2) + z*(exp(-z^2))')
    = -2*(exp(-z^2) + z*(-2*z*exp(-z^2)))
{3} = -2* (1 -2*z^2) *exp(-z^2)                               = -2*(1*{1}+{2}*z)
-2*((1-2*z^2)*exp(-z^2))' =
    = -2*((1-2*z^2)'*exp(-z^2) + (1-2*z^2)*(exp(-z^2))')
    = -2*(-4*z*exp(-z^2) + (1-2*z^2)*(-2*z*exp(-z^2)))
{4} = -2*(-4*z -2*(1-2*z^2)*z) *exp(-z^2)                     = -2*(2*{2}+{3}*z)
    =  4*(3*z-2*z^3) *exp(-z^2)
4*((3*z-2*z^3)*exp(-z^2))' =
    = 4*((3*z-2*z^3)'*exp(-z^2) + (3*z-2*z^3)*(exp(-z^2))')
    = 4*(3*(1-2*z^2)*exp(-z^2) + (3*z-2*z^3)*(-2*z*exp(-z^2)))
{5} = -2*(3*-2*(1-2*z^2) + 4*(3*z-2*z^3)*z) *exp(-z^2)        = -2*(3*{3}+{4}*z)
    = 4*(3-12*z^2+4*z^4) *exp(-z^2)
4*((3-12*z^2+4*z^4)*exp(-z^2))' =
    = 4*((3-12*z^2+4*z^4)'*exp(-z^2) + (3-12*z^2+4*z^4)*(exp(-z^2))')
    = 4*((-24*z+16*z^3)*exp(-z^2) + (3-12*z^2+4*z^4)*(-2*z*exp(-z^2)))
    = 4*(-2*(12*z-8*z^3) -2*(3-12*z^2+4*z^4)*z) *exp(-z^2)
{6} = -2*(16*(3*z-2*z^3) +4*(3-12*z^2+4*z^4)*z) *exp(-z^2)    = -2*(4*{4}+{5}*z)
    = 4*(-30*z+40*z^3-8*z^5) *exp(-z^2)
...
*/

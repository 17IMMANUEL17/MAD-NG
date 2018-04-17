#ifndef MAD_TPSA_PRIV_H
#define MAD_TPSA_PRIV_H

/*
 o-----------------------------------------------------------------------------o
 |
 | Truncated Power Series Algebra module implementation (private)
 |
 | Methodical Accelerator Design - Copyright CERN 2016+
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

#include "mad_bit.h"
#include "mad_tpsa.h"

// --- types ------------------------------------------------------------------o

struct tpsa { // warning: must be kept identical to LuaJIT definition (cmad.lua)
  desc_t *d;
  ord_t   lo, hi, mo; // lowest/highest used ord, max ord (allocated)
  bit_t   nz;
  num_t   coef[];
};

// --- macros -----------------------------------------------------------------o

#ifndef MAD_TPSA_NOHELPER

#define T           tpsa_t
#define NUM         num_t
#define FUN(name)   MKNAME(mad_tpsa_,name)
#define PFX(name)   name
#define VAL(num)    num
#define FMT         "%+6.4lE"
#define SELECT(R,C) R

#endif

// --- helpers ----------------------------------------------------------------o

static inline tpsa_t*
mad_tpsa_reset0 (tpsa_t *t)
{
  t->lo = t->mo;
  t->hi = t->nz = 0;
  t->coef[0] = 0;
  return t;
}

static inline tpsa_t*
mad_tpsa_copy0 (const tpsa_t *t, tpsa_t *r)
{
  if (t != r) {
    r->lo = t->lo;
    r->hi = MIN3(t->hi, r->mo, t->d->to);
    r->nz = mad_bit_hcut(t->nz, r->hi);
    if (r->lo) r->coef[0] = 0;
  }
  return r;
}

static inline tpsa_t*
mad_tpsa_update0 (tpsa_t *t)
{
  idx_t *pi = t->d->ord2idx;
  for (ord_t o = t->lo; o <= t->hi; ++o) {
    if (mad_bit_get(t->nz,o)) {
      idx_t i = pi[o];
      while (i < pi[o+1] && !t->coef[i]) ++i;
      if (i < pi[o+1]) t->nz = mad_bit_clr(t->nz, o);
    }
  }
  return t;
}

static inline tpsa_t*
mad_tpsa_gettmp (const tpsa_t *t, const str_t func)
{
  D *d = t->d;
  int tid = omp_get_thread_num();
  assert(d->ti[tid] < DESC_MAX_TMP);
  tpsa_t *tmp = d->t[ tid*DESC_MAX_TMP + d->ti[tid]++ ];
  TRC_TMP(printf("GET_TMPX%d[%d]: %p in %s()\n",
                 tid, d->ti[tid]-1, (void*)tmp, func));
  tmp->mo = t->mo;
  return tmp; // mad_tpsa_reset0(tmp);
}

static inline void
mad_tpsa_reltmp (tpsa_t *tmp, const str_t func)
{
  D *d = tmp->d;
  int tid = omp_get_thread_num();
  TRC_TMP(printf("REL_TMPX%d[%d]: %p in %s()\n",
                 tid, d->ti[tid]-1, (void*)tmp, func));
  assert(d->t[ tid*DESC_MAX_TMP + d->ti[tid]-1 ] == tmp);
  --d->ti[tid]; //, tmp->mo = d->mo; // ensure stack-like usage of temps
}

// --- end --------------------------------------------------------------------o

#endif // MAD_TPSA_PRIV_H

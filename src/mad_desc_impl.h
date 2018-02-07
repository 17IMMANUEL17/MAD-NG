#ifndef MAD_DESC_PRIV_H
#define MAD_DESC_PRIV_H

/*
 o-----------------------------------------------------------------------------o
 |
 | Descriptor (TPSA) module implementation (private)
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

#include "mad_log.h"
#include "mad_bit.h"
#include "mad_desc.h"
#include "mad_tpsa.h"
#include "mad_ctpsa.h"

// --- types ------------------------------------------------------------------o

struct desc {  // WARNING: needs to be identical with Lua for compatibility
  int      id;          // index in list of registered descriptors
  int      nmv, nv, nc; // number of mvars, number of all vars, number of coefs
  ord_t    mo, ko,      // maximum order for mvars and knobs
           trunc;       // truncation order for operations; always <= mo
               // end of compatibility with Lua

  size_t   size;       // bytes used by current desc

  str_t   *mvar_names; // names of mvars
  ord_t   * var_ords,  // limiting order for each monomial variable
          *mvar_ords,  // max order for each TPSA in map -- used just for desc comparison
          *monos,      // 'matrix' storing the monomials (sorted by ord)
          *ords,       // order of each mono of To
         **To,         // Table by orders -- pointers to monos, sorted by order
         **Tv,         // Table by vars   -- pointers to monos, sorted by vars
         **ocs;        // ocs[t,i] -> o; in mul, compute o on thread t; 3 <= o <= mo; terminated with 0

  idx_t   *sort_var,   // array
          *ord2idx,    // order to polynomial start index in To (i.e. in TPSA coef[])
          *tv2to,      // lookup tv->to
          *to2tv,      // lookup to->tv
          *H,          // indexing matrix, in Tv
         **L,          // multiplication indexes -- L[oa][ob] -> lc; lc[ia][ib] -> ic
        ***L_idx;      // L_idx[oa,ob] -> [start] [split] [end] idxs in L

  // WARNING: temps must be used with care (internal side effects)
   tpsa_t * t[5];      // temps for mul[0], fix pts[1-3], div & funs[4], alg funs[1-3] for aliasing
  ctpsa_t *ct[5];      // temps for ctpsa
};

// --- interface --------------------------------------------------------------o

#define D desc_t

idx_t    mad_desc_get_idx         (const D *d, int n, const ord_t m [n]);
idx_t    mad_desc_get_idx_sp      (const D *d, int n, const idx_t m [n]);
int      mad_desc_get_mono        (const D *d, int n,       ord_t m_[n], idx_t i);
int      mad_desc_mono_isvalid    (const D *d, int n, const ord_t m [n]);
int      mad_desc_mono_isvalid_sp (const D *d, int n, const idx_t m [n]);
int      mad_desc_mono_nxtbyvar   (const D *d, int n,       ord_t m [n]);

tpsa_t*  mad_tpsa_newd  (D *d, ord_t mo);
void     mad_tpsa_del   (tpsa_t *t);

ctpsa_t* mad_ctpsa_newd (D *d, ord_t mo);
void     mad_ctpsa_del  (ctpsa_t *t);

// --- helpers ----------------------------------------------------------------o

static inline idx_t
hpoly_idx (idx_t ib, idx_t ia, idx_t ia_size)
{
  return ib*ia_size + ia;
}

// --- end --------------------------------------------------------------------o

#endif // MAD_DESC_PRIV_H

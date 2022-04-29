/*
  Copyright (c) 2015 Synopsys, Inc. All rights reserved worldwide.
  The information contained in this file is the proprietary and confidential
  information of Synopsys, Inc. and its licensors, and is supplied subject to,
  and may be used only by Synopsys customers in accordance with the terms and
  conditions of a previously executed license agreement between Synopsys and that
  customer.
*/

/* user_nodefs.h
 *
 * Add company-specific nodefs here.  As the documentation for Prevent
 * describes, a nodef changes a function-style macro into a function
 * call.  The benefit of this change is that Prevent cannot identify
 * macro names during the analysis, but it can identify function
 * calls.  Thus, if, for example, you want to configure a
 * company-specific assert macro, you will first need to convert that
 * macro into a function call, then you will need to use the
 * cov-make-library utility to create a model for the new function
 * call.
 *
 * NOTE: In C++, it is critical that you create prototypes for the new
 * function calls that you are creating with the #nodef directive.  If
 * you #nodef my_assert, then you must make prototypes for every
 * possible type signature of my_assert.  Because C++ allows
 * overloading, though, it is perfectly fine to have more than one
 * prototype for a single function call.
 */

#if 0
#include <glib/gprintf.h>

#define tcc_printf (void)g_printf
#define CONV_PTR(PTR) ((void *)PTR)

#define IGNORE_1

#nodef GST_CAT_LEVEL_LOG(cat,level,object,...)      IGNORE_1
#nodef G_OBJECT_CLASS(a)                            IGNORE_1

#else 

#define IGNORE_1

#nodef MODULE_DEVICE_TABLE(type, name)    IGNORE_1
#nodef MODULE_AUTHOR(_author)             IGNORE_1
#nodef MODULE_LICENSE(_licence_)          IGNORE_1
#nodef MODULE_DESCRIPTION(_str_)          IGNORE_1

#nodef EXPORT_SYMBOL(x)                   IGNORE_1

#nodef module_init(a)                     IGNORE_1
#nodef module_exit(a)                     IGNORE_1

#nodef mutex_init(m)                      IGNORE_1
#nodef mutex_lock(m)                        1
#nodef mutex_unlock(m)                      1

#nodef atomic_read(v)                       1
#nodef atomic_set(v, i)                     1
#nodef atomic_inc(ptr)                      1
#nodef atomic_andnot(v, ptr)                1
#nodef atomic_or(v, ptr)                    1

#nodef spin_lock_init(ptr)                  1

#nodef readl							1

#nodef kernel_read(s,d,f,p)					1
//#nodef vfs_read(s,d,f,p)					1

#nodef list_first_entry(ptr, type, member)  0

//////////////////////////////////////////////////////////////////////////
//V 1.7.2
#nodef udelay(a)                            IGNORE_1

//////////////////////////////////////////////////////////////////////////
//V 1.7.3
#nodef VPU_IS_ERR(a)                           ((bool)false)

//////////////////////////////////////////////////////////////////////////
//V1. 8
//
//#nodef kthread_run(threadfn,data,namefmt,__VA_ARGS__...) NULL
//#nodef init_waitqueue_head(wq_head)		1

//////////////////////////////////////////////////////////////////////////
//V2.0
//#nodef wait_event_interruptible_timeout(wq_head, condition, timeout) 1
//#nodef compat_ptr(v)			1v

#nodef kthread_run(threadfn,data,namefmt,__VA_ARGS__...) NULL
#nodef init_waitqueue_head(a)               IGNORE_1
#nodef container_of(a,b,c)                  (((b) *)(a))

#endif
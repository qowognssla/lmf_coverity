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

/** Enter company-specific nodefs here:
#nodef my_assert
...
**/
#include <glib/gprintf.h>

#define tcc_printf (void)g_printf
#define CONV_PTR(PTR) ((void *)PTR)

//#nodef GST_CAT_LEVEL_LOG(cat,level,object,...) gst_debug_log ((cat), (level), __FILE__, GST_FUNCTION, __LINE__,	(GObject *) (object), __VA_ARGS__);
//#nodef GST_CAT_LEVEL_LOG(cat,level,object,...) G_STMT_START{ \
//      tcc_printf("%d ", cat); \
//      tcc_printf("%d ", level); \
//      tcc_printf("%d ", (void *)object); \
//      tcc_printf(...); \
//}G_STMT_END 

#nodef GST_CAT_LEVEL_LOG(cat,level,object,...) \
  (void)g_printf("%p", object); \
  (void)g_printf(__VA_ARGS__); 


#nodef GST_TRACE(...)		GST_CAT_LEVEL_LOG (GST_CAT_DEFAULT, GST_LEVEL_TRACE,   NULL, __VA_ARGS__)

void CATEGORY_INIT(GObject cat, char *name, int color, char * description);

#nodef GST_DEBUG_CATEGORY_INIT(cat,name,color,description) CATEGORY_INIT(cat, name, color, description);
#nodef G_UNLIKELY(expr) (expr)

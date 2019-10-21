#ifndef ARCH_PIPCALL_H
#define ARCH_PIPCALL_H

#define LAST_PIPCALL PIPCALL_YIELD

#define PIPCALL_OUTB             6
#define PIPCALL_INB              7
#define PIPCALL_OUTW             8
#define PIPCALL_INW              9
#define PIPCALL_OUTL             10
#define PIPCALL_INL              11
#define PIPCALL_CREATEPARTITION  12
#define PIPCALL_COUNTTOMAP       13
#define PIPCALL_PREPARE          14
#define PIPCALL_ADDVADDR         15
#define PIPCALL_DISPATCH         16
#define PIPCALL_OUTADDRL         17
#define PIPCALL_TIMER            18
#define PIPCALL_RESUME           19
#define PIPCALL_REMOVEVADDR      20
#define PIPCALL_MAPPEDINCHILD    21
#define PIPCALL_DELETEPARTITION  22
#define PIPCALL_COLLECT          23
#define PIPCALL_YIELD            24

#define PIPCALL_NARGS_OUTB             2
#define PIPCALL_NARGS_INB              1
#define PIPCALL_NARGS_OUTW             2
#define PIPCALL_NARGS_INW              1
#define PIPCALL_NARGS_OUTL             2
#define PIPCALL_NARGS_INL              1
#define PIPCALL_NARGS_CREATEPARTITION  5
#define PIPCALL_NARGS_COUNTTOMAP       2
#define PIPCALL_NARGS_PREPARE          4
#define PIPCALL_NARGS_ADDVADDR         6
#define PIPCALL_NARGS_DISPATCH         5
#define PIPCALL_NARGS_OUTADDRL         2
#define PIPCALL_NARGS_TIMER            0
#define PIPCALL_NARGS_RESUME           2
#define PIPCALL_NARGS_REMOVEVADDR      2
#define PIPCALL_NARGS_MAPPEDINCHILD    1
#define PIPCALL_NARGS_DELETEPARTITION  1
#define PIPCALL_NARGS_COLLECT          1
#define PIPCALL_NARGS_YIELD            5

#endif
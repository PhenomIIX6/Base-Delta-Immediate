.global _start
_start:
    li sp, 0x81000000
    li gp, 0x82000000
    call main

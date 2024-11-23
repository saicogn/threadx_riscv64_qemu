# Define macros for conditional compilation.
# Support customization in the Makefile files for each project separately.
# And also support customization in common.mk

ifeq (${ARCH}, RV64)
DEFS += -DCONFIG_RV64
DEFS += -D__riscv_xlen=64
else
# RV32 or default is 32bit
DEFS += -DCONFIG_RV32
DEFS += -D__riscv_xlen=32
endif

ifeq (${SYSCALL}, y)
DEFS += -DCONFIG_SYSCALL
endif


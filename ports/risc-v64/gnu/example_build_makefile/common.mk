# Common part for the Makefile.
# This file will be included by the Makefile of each project.

# Custom Macro Definition (Common part)
ARCH = RV64

include ../defines.mk
DEFS +=

CROSS_COMPILE = riscv64-unknown-elf-
# CROSS_COMPILE = riscv64-linux-gnu-
CFLAGS += -nostdlib -fno-builtin -g -Wall
# CFLAGS += -g -Wall
ifeq (${ARCH}, RV64)
#CFLAGS += -march=rv64g -mabi=lp64 -mcmodel=medany
CFLAGS += -march=rv64g -mabi=lp64d -mcmodel=medany
else
CFLAGS += -march=rv32g -mabi=ilp32
endif

# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2 -std=gnu11" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=rv64imafdc" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mabi=lp64d" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffunction-sections" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fdata-sections" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wl,--gc-sections" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-pointer-to-int-cast" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-builtin" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wno-missing-field-initializers" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -g -Wall -Wextra" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -nostdlib" )
# set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mcmodel=medany" )

ifeq (${ARCH}, RV64)
QEMU = qemu-system-riscv64
else
QEMU = qemu-system-riscv32
endif

QFLAGS = -nographic -smp 1 -machine virt -bios none

GDB = gdb-multiarch
CC = ${CROSS_COMPILE}gcc
OBJCOPY = ${CROSS_COMPILE}objcopy
OBJDUMP = ${CROSS_COMPILE}objdump
MKDIR = mkdir -p
RM = rm -rf

OUTPUT_PATH = out

# SRCS_ASM & SRCS_C are defined in the Makefile of each project.
OBJS_ASM := $(addprefix ${OUTPUT_PATH}/, $(patsubst %.S, %.o, ${SRCS_ASM}))
OBJS_C   := $(addprefix $(OUTPUT_PATH)/, $(patsubst %.c, %.o, ${SRCS_C}))
OBJS = ${OBJS_ASM} ${OBJS_C}

# threadx static lib
GNU_AR := ${CROSS_COMPILE}ar
THREADX_FILE_LIST := threadx_file_list.mk
THREADX_LIB := 
TX_PATH := tx
# THREADX_OBJ := tx.a
DIR=$(shell pwd)
COMMON_PATH=$(DIR)/../../../../../common
PORT_PATH=$(DIR)/../../src
TX_INCLUDES = -I$(COMMON_PATH)/inc -I$(DIR)/../../inc -I$(DIR)
TX_CFLAGS := $(TX_INCLUDES) # -std=c99 
include ${THREADX_FILE_LIST}

ELF = ${OUTPUT_PATH}/os.elf
BIN = ${OUTPUT_PATH}/os.bin

USE_LINKER_SCRIPT ?= true
ifeq (${USE_LINKER_SCRIPT}, true)
LDFLAGS = -T ${OUTPUT_PATH}/os.ld.generated
else
LDFLAGS = -Ttext=0x80000000
endif

.DEFAULT_GOAL := all
all: ${OUTPUT_PATH} ${TX_PATH} ${ELF}

##############################################################
# tx path
.PHONY: ${TX_PATH}
${TX_PATH}:
	@${MKDIR} $@
	@${MKDIR} $@/generic
#	@echo "make dir ${TX_PATH} and ${TX_PATH}/generic"
#	@echo "common path = ${COMMON_PATH}"
#	@echo "qemu depend objs = ${QEMU_DEPEND_OBJS}"
#	@echo "tx generic objs = ${GENERIC_OBJS}"

${OUTPUT_PATH}:
	@${MKDIR} $@

# ${THREADX_OBJ}: ${GENERIC_OBJS} ${PORT_OBJS}
# 	@echo "generate ${THREADX_OBJ} -> $(THREADX_OBJ)"
# 	${GNU_AR} ${DEFS} ${CFLAGS} ${TX_CFLAGS} -o $@ ${GENERIC_OBJS} ${PORT_OBJS}

# ${GENERIC_OBJS}
$(TX_PATH)/generic/%.o: $(COMMON_PATH)/src/%.c
	@echo "CC $@"
	${CC} ${CFLAGS} ${TX_CFLAGS} -c -o $@ $<
# ${PORT_OBJS}
${TX_PATH}/%.o: ${PORT_PATH}/%.c
	@echo "CC $@"
	${CC} ${CFLAGS} ${TX_CFLAGS} -c -o $@ $<
${TX_PATH}/%.o: ${PORT_PATH}/%.S
	@echo "CC $@"
	${CC} ${CFLAGS} ${TX_CFLAGS} -c -o $@ $<

print:
	@echo ${PORT_OBJS}

# $(OUTPUT_FOLDER)/%.o: ../src/%.c $(DIR)/Makefile
# 	filename=`basename $<`; \
# 	echo CC $$filename; \
# 	$(CC) $(CFLAGS) -MT $@ -MD -MP -MF $(OUTPUT_FOLDER)/$$filename.d -c -o $@ $<

# $(OUTPUT_FOLDER)/generic/%.o: $(COMMON_PATH)/src/%.c $(DIR)/Makefile
# 	filename=`basename $<`; \
# 	echo CC $$filename; \
# 	$(CC) $(CFLAGS) -MT $@ -MD -MP -MF $(OUTPUT_FOLDER)/$$filename.d -c -o $@ $<
#################################################################

# start.o must be the first in dependency!
#
# For USE_LINKER_SCRIPT == true, before do link, run preprocessor manually for
# linker script.
# -E specifies GCC to only run preprocessor
# -P prevents preprocessor from generating linemarkers (#line directives)
# -x c tells GCC to treat your linker script as C source file
#${ELF}: ${OBJS} ${THREADX_OBJ}
${ELF}: ${OBJS} ${GENERIC_OBJS} ${PORT_OBJS}
ifeq (${USE_LINKER_SCRIPT}, true)
	${CC} -E -P -x c ${DEFS} ${CFLAGS} ${TX_CFLAGS} os.ld > ${OUTPUT_PATH}/os.ld.generated
endif
	${CC} ${CFLAGS} ${TX_CFLAGS} ${LDFLAGS} -o ${ELF} $^
	${OBJCOPY} -O binary ${ELF} ${BIN}

${OUTPUT_PATH}/%.o : %.c
	${CC} ${DEFS} ${CFLAGS} ${TX_CFLAGS} -c -o $@ $<

${OUTPUT_PATH}/%.o : %.S
	${CC} ${DEFS} ${CFLAGS} ${TX_CFLAGS} -c -o $@ $<

run: all
	@${QEMU} -M ? | grep virt >/dev/null || exit
	@echo "Press Ctrl-A and then X to exit QEMU"
	@echo "------------------------------------"
	@${QEMU} ${QFLAGS} -kernel ${ELF}

.PHONY : debug
debug: all
	@echo "Press Ctrl-C and then input 'quit' to exit GDB and QEMU"
	@echo "-------------------------------------------------------"
	@${QEMU} ${QFLAGS} -kernel ${ELF} -s -S &
	@${GDB} ${ELF} -q -x ../gdbinit

.PHONY : code
code: all
	@${OBJDUMP} -S ${ELF} | less

.PHONY : clean
clean:
	@${RM} ${OUTPUT_PATH}
	@${RM} ${TX_PATH}

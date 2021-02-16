#
#       !!!! Do NOT edit this makefile with an editor which replace tabs by spaces !!!!
#
##############################################################################################
#
# On command line:
#
# make all = Create project
#
# make clean = Clean project files.
#
# To rebuild project do "make clean" and "make all".
#
# Included originally in the yagarto projects. Original Author : Michael Fischer
#
# Modified by Ricky Rininger 2019
##############################################################################################
# Start of default section
#
CCPREFIX = arm-none-eabi-
CC   = $(CCPREFIX)gcc
CP   = $(CCPREFIX)objcopy
AS   = $(CCPREFIX)gcc -x assembler-with-cpp
GDBTUI = $(CCPREFIX)gdb -tui
HEX  = $(CP) -O ihex
BIN  = $(CP) -O binary -S
MCU  = cortex-m4

# Configuration
# Use newlib-nano. To disable, specify USE_NANO=
USE_NANO=--specs=nano.specs

# Use semihosting or not
USE_SEMIHOST=--specs=rdimon.specs
USE_NOHOST=--specs=nosys.specs


# List all C defines here
DDEFS =
#
# Define project name and Ram/Flash mode here
PROJECT        = driver_test

# List C source files here

SRC  = ./src/main.c
SRC += ./drivers/src/gpio.c
SRC += ./drivers/src/rcc.c
SRC += ./CMSIS/Device/ST/STM32F4xx/Source/Templates/system_stm32f4xx.c
SRC += ./CMSIS/Device/ST/STM32F4xx/Source/Templates/startup_stm32f407xx.c

# List all include directories here
INCDIRS = ./inc \
INCDIRS += ./CMSIS/Core/Include \
INCDIRS += ./CMSIS/Device/ST/STM32F4xx/Include
INCDIRS += ./drivers/inc

# List the user directory to look for the libraries here
LIBDIRS +=

# List all user libraries here
LIBS =

# Define optimisation level here
OPT = -Og


# Define linker script file here
LINKER_SCRIPT = ./stm32f407xx_gcc.ld


INCDIR  = $(patsubst %,-I%, $(INCDIRS))
LIBDIR  = $(patsubst %,-L%, $(LIBDIRS))
LIB     = $(patsubst %,-l%, $(LIBS))
##reference only flags for run from ram...not used here
##DEFS    = $(DDEFS) $(UDEFS) -DRUN_FROM_FLASH=0 -DVECT_TAB_SRAM

## run from Flash
DEFS    = $(DDEFS) -DRUN_FROM_FLASH=1

OBJS  = $(SRC:.c=.o)
MCFLAGS = -mcpu=$(MCU)

ASFLAGS = $(MCFLAGS) -g -gdwarf-2 -mthumb  -Wa,-amhls=$(<:.s=.lst)
CPFLAGS = $(MCFLAGS) $(OPT) -g -gdwarf-2 -mthumb -ffunction-sections -fomit-frame-pointer -Wall -Werror -Wstrict-prototypes -fverbose-asm -Wa,-ahlms=$(<:.c=.lst) $(DEFS)
LDFLAGS = $(USE_NOHOST) $(MCFLAGS) -g -gdwarf-2 -mthumb -T$(LINKER_SCRIPT) -Wl,-Map=$(PROJECT).map,--cref,--gc-sections,--print-gc-sections,--no-warn-mismatch $(LIBDIR) $(LIB)

#
# makefile rules
#

all: $(OBJS) $(PROJECT).elf  $(PROJECT).hex $(PROJECT).bin
	$(TRGT)size $(PROJECT).elf

%.o: %.c
	$(CC) -c $(CPFLAGS) -I . $(INCDIR) $< -o $@

%.o: %.s
	$(AS) -c $(ASFLAGS) $< -o $@

%.elf: $(OBJS)
	$(CC) $(OBJS) $(LDFLAGS) $(LIBS) -o $@

%.hex: %.elf
	$(HEX) $< $@

%.bin: %.elf
	$(BIN)  $< $@

flash_openocd: $(PROJECT).bin
	openocd -s ~/tools/EmbeddedArm/openocd-bin/share/openocd/scripts/ -f board/stm32f4discovery_V2-1.cfg -c "init" -c "reset halt" -c "sleep 100" -c "wait_halt 2" -c "flash write_image erase $(PROJECT).bin 0x08000000" -c "sleep 100" -c "verify_image $(PROJECT).bin 0x08000000" -c "sleep 100" -c "reset run" -c shutdown

flash_stlink: $(PROJECT).bin
	st-flash write $(PROJECT).bin 0x8000000

erase_openocd:
	openocd -s ~/tools/EmbeddedArm/openocd-bin/share/openocd/scripts/ -f board/stm32f4discovery_V2-1.cfg -c "init" -c "reset halt" -c "sleep 100" -c "stm32f1x mass_erase 0" -c "sleep 100" -c shutdown

erase_stlink:
	st-flash erase

debug_openocd: $(PROJECT).elf flash_openocd
	xterm -e openocd -s ~/tools/EmbeddedArm/openocd-bin/share/openocd/scripts/ -f board/stm32f4discovery_V2-1.cfg -c "init" -c "halt" -c "reset halt" &
	$(GDBTUI) --eval-command="target remote localhost:3333" $(PROJECT).elf

debug_stlink: $(PROJECT).elf
	xterm -e st-util &
	$(GDBTUI) --eval-command="target remote localhost:4242"  $(PROJECT).elf -ex 'load'

clean:
	-rm -rf $(OBJS)
	-rm -rf $(PROJECT).elf
	-rm -rf $(PROJECT).map
	-rm -rf $(PROJECT).hex
	-rm -rf $(PROJECT).bin
	-rm -rf $(SRC:.c=.lst)
	-rm -rf $(ASRC:.s=.lst)
# *** EOF ***

# ---------------------------------------------
# Top directories and pre-inspection
# ---------------------------------------------

DIR_TOP      := $(shell pwd)
DIR_QEMU     := $(DIR_TOP)/QEMU-DASICS
DIR_NEMU     := $(DIR_TOP)/NEMU
DIR_XS       := $(DIR_TOP)/xiangshan-dasics
DIR_BBL_QEMU := $(DIR_TOP)/riscv-pk-qemu
DIR_BBL_NEMU := $(DIR_TOP)/riscv-pk-nemu
DIR_LINUX    := $(DIR_TOP)/riscv-linux
DIR_ROOTFS   := $(DIR_TOP)/riscv-rootfs

ifndef RISCV
$(error Please set environment variable RISCV. Please take a look at README)
endif

# ---------------------------------------------
# Variables and rules of QEMU-DASICS
# ---------------------------------------------

TARGET_QEMU := $(DIR_QEMU)/build/qemu-system-riscv64
TARGET_IMG  := $(DIR_QEMU)/build/img

.PHONY: qemu

qemu: $(TARGET_QEMU)

qemu-clean:
	-$(MAKE) -C $(DIR_QEMU) clean

$(TARGET_QEMU):
	cd $(DIR_QEMU) && ./configure --target-list=riscv64-softmmu
	$(MAKE) -C $(DIR_QEMU) -j`nproc`

$(TARGET_IMG): $(TARGET_QEMU)
	$(DIR_QEMU)/build/qemu-img create -f raw $(TARGET_IMG) 1G
	mkfs.ext4 $(TARGET_IMG)

# ---------------------------------------------
# Variables and rules of NEMU
# ---------------------------------------------

NEMU_ENV        := NEMU_HOME=$(DIR_NEMU)
DIR_SOFTFLOAT   := $(DIR_NEMU)/resource/softfloat/repo/build/Linux-x86_64-GCC
TARGET_NEMU_ELF := $(DIR_NEMU)/build/riscv64-nemu-interpreter
TARGET_NEMU_SO  := $(TARGET_NEMU_ELF)-so

.PHONY: nemu nemu-clean

nemu: $(TARGET_NEMU_ELF) $(TARGET_NEMU_SO)

nemu-clean:
ifneq ($(wildcard $(DIR_SOFTFLOAT)),)
	$(NEMU_ENV) $(MAKE) -C $(DIR_SOFTFLOAT) clean
endif
	$(NEMU_ENV) $(MAKE) -C $(DIR_NEMU) clean

$(TARGET_NEMU_ELF):
ifneq ($(wildcard $(DIR_SOFTFLOAT)),)
	$(NEMU_ENV) $(MAKE) -C $(DIR_SOFTFLOAT) clean
endif
	$(NEMU_ENV) $(MAKE) -C $(DIR_NEMU) riscv64-xs-dasics_defconfig
	$(NEMU_ENV) $(MAKE) -C $(DIR_NEMU) -j`nproc`

$(TARGET_NEMU_SO):
ifneq ($(wildcard $(DIR_SOFTFLOAT)),)
	$(NEMU_ENV) $(MAKE) -C $(DIR_SOFTFLOAT) clean
endif
	$(NEMU_ENV) $(MAKE) -C $(DIR_NEMU) riscv64-xs-dasics-ref_defconfig
	$(NEMU_ENV) $(MAKE) -C $(DIR_NEMU) -j`nproc`

# ---------------------------------------------
# Variables and rules of Xiangshan-DASICS
# ---------------------------------------------

XS_ENV         := NOOP_HOME=$(DIR_XS) NEMU_HOME=$(DIR_NEMU)
XS_CONFIG      ?= MinimalConfig
XS_EMU_THREADS ?= 2
TARGET_XS_EMU  := $(DIR_XS)/build/emu

.PHONY: xs-emu xs-emu-clean

xs-emu: $(TARGET_XS_EMU)

xs-emu-clean:
	$(XS_ENV) $(MAKE) -C $(DIR_XS) clean

$(TARGET_XS_EMU):
	$(XS_ENV) $(MAKE) -C $(DIR_XS) emu CONFIG=$(XS_CONFIG) EMU_THREADS=$(XS_EMU_THREADS) -j`nproc`

# ---------------------------------------------
# Variables and rules of riscv-rootfs
# ---------------------------------------------

ROOTFS_ENV := RISCV_ROOTFS_HOME=$(DIR_ROOTFS)

.PHONY: rootfs-clean

rootfs-clean:
	$(ROOTFS_ENV) $(MAKE) -C $(DIR_ROOTFS) clean

# ---------------------------------------------
# Variables and rules of riscv-linux
# ---------------------------------------------

.PHONY: linux-clean

linux-clean:
	$(MAKE) -C $(DIR_LINUX) clean && $(MAKE) -C $(DIR_LINUX) mrproper

# ---------------------------------------------
# Variables and rules of riscv-pk-qemu
# ---------------------------------------------

TARGET_BBL_QEMU := $(DIR_BBL_QEMU)/build/bbl.bin

.PHONY: bbl-qemu bbl-qemu-clean

bbl-qemu: $(TARGET_BBL_QEMU)

bbl-qemu-clean:
	$(MAKE) -C $(DIR_BBL_QEMU) clean

$(TARGET_BBL_QEMU):
	$(MAKE) -C $(DIR_LINUX) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- dasics_defconfig
	$(ROOTFS_ENV) $(MAKE) -C $(DIR_BBL_QEMU) qemu -j`nproc`

# ---------------------------------------------
# Variables and rules of riscv-pk-nemu
# ---------------------------------------------

TARGET_BBL_NEMU := $(DIR_BBL_NEMU)/build/bbl.bin

.PHONY: bbl-nemu bbl-nemu-clean

bbl-nemu: $(TARGET_BBL_NEMU)

bbl-nemu-clean:
	$(MAKE) -C $(DIR_BBL_NEMU) clean

$(TARGET_BBL_NEMU):
	$(MAKE) -C $(DIR_LINUX) ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- emu_defconfig
	$(ROOTFS_ENV) $(MAKE) -C $(DIR_BBL_NEMU) -j`nproc`

# ---------------------------------------------
# Top Makefile rules
# ---------------------------------------------

.PHONY: init run-qemu run-nemu nodiff difftest clean

init:
	git pull origin xs-dasics-v1.0-release
	git submodule update --init --depth 1 $(DIR_QEMU)
	git submodule update --init           $(DIR_NEMU)
	git submodule update --init           $(DIR_XS)
	git submodule update --init           $(DIR_BBL_QEMU)
	git submodule update --init           $(DIR_BBL_NEMU)
	git submodule update --init --depth 1 $(DIR_LINUX)
	git submodule update --init           $(DIR_ROOTFS)
	$(MAKE) -C $(DIR_XS) init

run-qemu: $(TARGET_QEMU) $(TARGET_IMG) $(TARGET_BBL_QEMU)
	$(TARGET_QEMU) -M virt -m 1G -bios none -kernel $(TARGET_BBL_QEMU) \
		-nographic -append "console=ttyS0 rw root=/dev/vda" \
		-drive file=$(TARGET_IMG),format=raw,id=hd0 \
		-device virtio-blk-device,drive=hd0

run-nemu: $(TARGET_NEMU_ELF) $(TARGET_BBL_NEMU)
	$(TARGET_NEMU_ELF) -b $(TARGET_BBL_NEMU)

nodiff: $(TARGET_XS_EMU) $(TARGET_BBL_NEMU)
	$(TARGET_XS_EMU) -i $(TARGET_BBL_NEMU) --no-diff 2>/dev/null

difftest: $(TARGET_NEMU_SO) $(TARGET_XS_EMU) $(TARGET_BBL_NEMU)
	$(TARGET_XS_EMU) -i $(TARGET_BBL_NEMU) --diff $(TARGET_NEMU_SO) 2>/dev/null

clean: qemu-clean nemu-clean xs-emu-clean bbl-qemu-clean bbl-nemu-clean linux-clean rootfs-clean

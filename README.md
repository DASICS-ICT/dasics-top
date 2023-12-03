# DASICS-TOP

## Introduction

A standalone and integrated repo to build riscv-linux based image for DASICS (Dynamic in-Address-Space Isolation by Code Segments).

There are several submodules as follows:

* QEMU-DASICS: QEMU emulator
* NEMU: NEMU emulator
* riscv-linux: linux kernel
* riscv-pk-qemu/nemu: BBL for QEMU/NEMU
* riscv-rootfs: simple rootfs
* xiangshan-dasics: hardware code for DASICS

## Usage

* Clone DASICS-TOP repository, and initialize it.

~~~bash
git clone https://github.com/DASICS-ICT/dasics-top.git && cd dasics-top
make init
~~~

* Run DASICS tests on QEMU:

~~~bash
make run-qemu
~~~

* Run one DASICS test on NEMU:
    * Note: Due to the limitation of NEMU, you can only run one test at one time. If you want to run another test, please modify `riscv-rootfs/rootfsimg/initramfs-emu.txt`

~~~bash
make run-nemu
~~~

* Run one DASICS test on Xiangshan-verilator:

~~~bash
make nodiff
~~~

* Run NEMU-Xiangshan difftesting:

~~~bash
make difftest
~~~

## FAQ

### Multiple definition of 'yylloc'

~~~bash
/usr/bin/ld: scripts/dtc/dtc-parser.tab.o:(.bss+0x10): multiple definition of `yylloc'; scripts/dtc/dtc-lexer.lex.o:(.bss+0x0): first defined here
collect2: error: ld returned 1 exit status
make[4]: *** [scripts/Makefile.host:99: scripts/dtc/dtc] Error 1
make[3]: *** [scripts/Makefile.build:558: scripts/dtc] Error 2
make[3]: *** Waiting for unfinished jobs....
~~~

* If you encounter such an error when compiling linux kernel, you can manually edit `riscv-linux/scripts/dtc/dtc-lexer-lex.c` ("YYLYTYPE yylloc" => "extern YYLYTYPE yylloc")
    * This is caused by toolchain version, and will not influence our DASICS functions
    * Reference is [here](https://github.com/BPI-SINOVOIP/BPI-M4-bsp/issues/4)

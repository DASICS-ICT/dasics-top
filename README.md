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
    * Note: Due to the limitation of NEMU, you can only run one test at one time. If you want to run another test, please modify `riscv-rootfs/rootfsimg/initramfs-dasics-2.txt`

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

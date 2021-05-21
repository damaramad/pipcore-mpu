# Readme

You can find more about the Pip protokernel at its [website](http://pip.univ-lille.fr).

The source code is covered by CeCILL-A licence.

The Pip Development Team:

*   Quentin Bergougnoux <quentin.bergougnoux@univ-lille.fr>
*   Julien Cartigny <julien.iguchi-cartigny@univ-lille.fr>
*   Gilles Grimaud <gilles.grimaud@univ-lille.fr>
*   Michaël Hauspie <michael.hauspie@univ-lille.fr>
*   Étienne Helluy Lafont <e.helluy-lafont@etudiant.univ-lille.fr>
*   Samuel Hym <samuel.hym@univ-lille.fr>
*   Narjes Jomaa <narjes.jomaa@univ-lille.fr>
*   David Nowak <david.nowak@univ-lille.fr>
*   Paolo Torrini <paolo.torrini@univ-lille.fr>
*   Mahieddine Yaker <mahieddine.yaker@univ-lille.fr>
*   Nicolas Dejon <nicolas.dejon@orange.com>

**Warning**: Pip-MPU is a project implementing Pip on ARM Cortex-M devices having a Memory Protection Unit (MPU).
It is forked from the Pip original code base.
However, as Pip is originally based on the Memory Management Unit (MMU), Pip-MPU is completely revised while retaining Pip's philosophy and methodology.
The rest of this document is linked to the original Pip and therefore **deprecated**.

## Getting started
You can generate the "Getting Started" tutorial by invoking `make gettingstarted`. The full documentation is generated by invoking `make doc`.

## Dependencies

Pip is known to build correctly with this toolchain:

* GCC i386, version 4.7.2 to 4.9
	* GCC 7.2 is known to be working as well
	* GNU Binutils version 2.29 is NOT working, as LD triggers a segmentation fault, use version 2.28 or lower instead
* NASM version 2.11.08
* COQ Proof Assistant version 8.5pl2
* GNU Sed version 4.2.2 (install it on an OSX build host through MacPorts : "gsed")
* grub-mkrescue (for ISO image generation; unnecessary for i386 target though)
* Doxygen version 1.8.10 (for documentation generation)
* haskell-stack version 1.2.0.2 (is a cross-platform program for developing Haskell projects)
* QEMU i386 version 2.6.50
* Texlive any version or another latex tools

## Building the Pip

You can pass several arguments to make to compile the Pip.

* `TARGET=...`: destination target (defaults to x86_multiboot)
* `PARTITION=...`: root partition (defaults to minimal)
* `KERNEL_ADDR=0x...`: Kernel load address (defaults to 0x100000)
* `PARTITION_ADDR=0x...`: Partition load address (defaults to 0x700000)
* `STACK_ADDR=0x...`: Early-boot stack address (defaults to 0x300000)
* `mrproper` | `clean` | `partition` | `all` | `kernel` | `proof` | `qemu` | `grub`: Requested build operation

## Building partitions
Each partition is located into `src/partitions/{architecture}/{partition}`.

* Configure the toolchain by copying `src/partitions/{architecture}/toolchain.mk.template` to `src/partitions/{architecture}/toolchain.mk`, then edit the latter to your needs.
* You can use the `minimal` partition as a base to develop more elaborated software.
* You can compile the partition by invoking `make` in the partition's directory, or use the `partition` build operation on the top directory (main `Makefile`).

## Kernel structure
The kernel is divided into four parts.

* MAL: The Memory Abstraction Layer is used to provide small functions to manipulate the MMU
* IAL: The Interrupt Abstraction Layer is used to provide small functions to manipulate the interrupt controller (configure, enable, disable...)
* Core: The logic of Pip
* Boot: The bootstrap code that initializes required hardware and then boots Pip

## Source code structure
* `_CoqProject` is a mandatory configuration file for Coq.
* `src/` is the source base directory.
* `src/MAL/`  is the Memory Abstraction Layer source folder.
* `src/IAL/` is the Interrupt Abstraction Layer source folder.
* `src/core/` is the Pip source folder.
* `src/boot/` contains the "cbits", i.e the required C and assembly code required to boot the coq kernel.
* `src/partitions/` contains the top-level partitions.
* `tools/` contains some scripts and tools that may be useful.
* `proof/` contains the Coq proof.
* `tests/` contains the test suites.

## Serial configuration
Pip can already boot on real hardware. If available, the first serial output (COM1) should be used for debugging output.
The required configuration is 38400 bauds, 8 bits, no parity, one stop bit. You can also enable automatic line feed and carriage return in Minicom (2.7+) for user-friendly output.

## Debugging with Bochs
Although QEMU is the reference x86 emulator for Pip, a configuration file for the Bochs emulator is also provided. Serial output is supported through a "bochscom" fifo created through the `mkfifo bochscom` command, and emulation can be started by invoking `bochs -q`.

Note that you need to generate Pip's ISO image through `make grub` before running Bochs.

## Compiling on Linux
The compilation on Linux should be as easy as to install the i386-elf toolchain as well as the other requirements, and use the Makefile to generate a binary image.
Use your favourite package manager to install i386 gcc (gcc-multilib), haskell-stack, QEMU, Coq, NASM, Doxygen and GRUB.

## Compiling on Darwin/OSX

### Using Homebrew : macOS 10.9 "Mavericks" and higher, including macOS 10.13 "High Sierra"

We're currently in the process of moving the toolchain setup process from MacPorts to Homebrew, and should be using it from now on.

* Install Homebrew (https://brew.sh/)
* Add the cross-compiler tap : `brew tap MrXedac/homebrew-gcc_cross_compilers`
* Install i386-elf-gcc : `brew install i386-elf-gcc` (this could take a while, as the i386 binutils and C compiler are compiled from scratch)
* Install opam, nasm, haskell-stack, qemu, gnu-sed, doxygen and Coq : `brew install opam nasm haskell-stack qemu gnu-sed doxygen coq@8.6.1`
	* Note : Homebrew provides a binary distribution of Coq available through `brew install coq`. At the moment we write these lines, the binary distribution of Coq is the one we want to install.
	* Further versions of Coq, and newer binary releases might break retrocompatibility with Pip's code. Because of this, installing the appropriate version through `brew install coq@8.6.1` is safer.

If you followed these instructions exactly, everything should be ready. If you installed another cross-compilation toolchain than i386-elf-, you should edit `conf/x86_multiboot.conf` and set the appropriate toolchain (defaults to i386-elf-).

### Using MacPorts : From macOS 10.9 "Mavericks" to macOS 10.12 "Sierra" (DEPRECATED)

* Install MacPorts
* Install git, nasm, qemu, i386-elf-gcc, gsed via MacPorts
* Install Coq (see User Guide)

If you followed these instructions exactly, everything should be ready. If you installed another cross-compilation toolchain than i386-elf-, you should edit `conf/x86_multiboot.conf` and set the appropriate toolchain (defaults to i386-elf-).

## Compiling on FreeBSD
Same thing as Darwin, using pkg instead of MacPorts.
You'll need to compile Coq from scratch though.

Note: FreeBSD is still an unsupported build platform.

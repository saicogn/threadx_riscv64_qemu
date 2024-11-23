# Introduce
移植ThreadX到RISC-V64，并运行在qemu-system-riscv64模拟器上。根据ThreaX官方demo提供一个开箱即用的演示代码。

RISC-V64移植具体内容参考另一个repo[1]，Qemu平台相关内容参考了汪辰老师的RVOS相关代码[2]，并支持浮点运算和浮点寄存器相关操作。

# How to use
需要先配置相关环境，按汪辰老师的RVOS环境配置即可。

```shell
$ sudo apt update
$ sudo apt install build-essential gcc make perl dkms git gcc-riscv64-unknown-elf gdb-multiarch qemu-system-misc
```

（注：仓库代码验证平台为ubuntu22.04，该版本apt安装的RISC-V工具栏缺少如stdio.h、string.h等文件，可以自行本地编译的RISC-V工具链解决[3]。ThreadX需要memset来初始化部分内存，故repo中使用RISC-V的newlib中的通用C语言memset函数[4]，后续将更换为汇编。）

common目录下为ThreadX官方通用文件，ports目录下为移植平台相关文件。使用Makefile构建，build目录下demo_threadx.c为demo程序。

```shell
cd ports/risc-v64/gnu/example_build_makefile/build/
make -jX # 多核编译, X为使用核心数
make run # 直接运行qemu
make debug # 运行gdb调试
```

# Reference
[1]ThreadX to RISC-V64：https://github.com/saicogn/ThreadX-to-RISC-V64

[2]RVOS mooc：https://github.com/plctlab/riscv-operating-system-mooc

[3]RISC-V toolchain：https://github.com/riscv-collab/riscv-gnu-toolchain

[4]RISC-V newlib：https://github.com/riscvarchive/riscv-newlib/blob/riscv-newlib-3.2.0/newlib/libc/string/memset.c

[5]ThreadX官方仓库：https://github.com/eclipse-threadx/threadx

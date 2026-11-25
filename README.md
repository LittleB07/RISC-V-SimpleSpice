# RISC-V SimpleSpice · 五级流水线 CPU

面向 Basys3（Artix-7，`xc7a35tcpg236-1`）的单发射五级流水线 CPU。工程使用 Vivado 2019.1，附带可直接运行的 24 节点最短路径 C 程序。

## 处理器实现

- **RV32I 整数指令**支持整数运算、移位、比较、访存、条件分支和跳转。流水线通过前递、暂停和冲刷处理相关性。
- **RISC-V M 扩展**实现全部 8 条乘除指令。多周期乘法器支持 `MUL`、`MULH`、`MULHSU`、`MULHU`，多周期除法器支持 `DIV`、`DIVU`、`REM`、`REMU`。
- **动态分支预测**在取指阶段查询 64 项直接映射 BTB，以两位饱和计数器预测条件分支方向。在执行阶段更新预测信息，预测失败时冲刷错误路径并修正 PC。

## FPGA 时序

Basys3 使用 100 MHz 系统时钟，时钟周期约束为 10.000 ns。Vivado 布线后报告显示所有已指定时序约束均满足。

| 指标 | 布线后结果 |
| --- | ---: |
| 建立时间裕量 WNS | +0.309 ns |
| 建立时间总负裕量 TNS | 0.000 ns |
| 保持时间裕量 WHS | +0.028 ns |
| 建立 / 保持时间违例端点 | 0 / 0 |

[查看 Vivado 布线后时序报告](reports/top_timing_summary_routed.rpt)

## 文件

- `RISCV_CPU.xpr`：Vivado 工程；顶层为 `top`。
- `RISCV_CPU.srcs/sources_1/new/`：RTL 和板上烧录的 `riscvtest.txt` 指令镜像。
- `RISCV_CPU.srcs/constrs_1/new/basys3_display.xdc`：Basys3 引脚和时钟约束。
- `RISCV_CPU.srcs/sim_1/new/tb_cpu.v`：最短路径功能与周期数仿真；`tb_all.v` 用于指令测试。
- `software/shortest_path.c`、`startup.S`、`build_shortest_path.ps1`：C 程序、启动入口和编译脚本。
- `software/shortest_path_riscvtest.txt`：供 Vivado 仿真读取的机器码，与当前板上指令镜像一致。

## 编译并更新指令镜像

需要 Windows PowerShell 和 `riscv-none-elf-gcc` 工具链。于工程根目录执行：

```powershell
.\software\build_shortest_path.ps1 -ToolBin 'D:\path\to\riscv-toolchain\bin'
```

脚本生成 `software/shortest_path_riscvtest.txt`、ELF、BIN 和反汇编，检查程序不含当前方案未使用的除法/取余指令。重新生成 bitstream 前，将生成的文本镜像复制到 `RISCV_CPU.srcs/sources_1/new/riscvtest.txt`。Vivado 综合从后一个文件初始化指令存储器；仅更新 C 文件或运行仿真不会更新已经生成的 bitstream。

## 仿真和上板

在 Vivado 中打开 `RISCV_CPU.xpr`，设 `tb_cpu` 为仿真顶层，运行 `Run All`。测试比较 Floyd–Warshall 参考结果与 CPU 运行 Dijkstra 的输出，并打印各起点周期数。若 Vivado 未找到 `shortest_path_riscvtest.txt`，将 `software/shortest_path_riscvtest.txt` 加入仿真源并标记为 Memory Initialization File。

板上先用 `SW4:0` 选择起点并按住复位，再松开复位等待 LED0 亮。随后 `SW4:0` 选择终点（0–23）；`SW8:7` 选择数码管显示：`00` 起点、`01` 起点到终点距离、`10` 运行时间（微秒）、`11` 全部 24 个节点的最短距离总和。详细验证数据和内存映射见 [software/SHORTEST_PATH.md](software/SHORTEST_PATH.md)。

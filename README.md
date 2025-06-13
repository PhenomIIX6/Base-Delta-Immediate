# Cache compression

Investigation of cache compression using the base-delta-immediate algorithm. The project consists of a system of modules on SystemVerilog, implementing a system with cache memory, cache controller and main memory. This is tested with a simple cocotb test and run in ModelSim.

## Cache

The cache has the following characteristics:
* 32 KiB 
* 8-way set associative
* 1024 lines
* 32B line size
* Write-through policy
* On-demand fill
* LFU replacement

## Compressor

The compressor selects two cache lines at adjacent addresses and performs compression. If compression is successful, the cache line stores two compressed cache lines.

## Requirements

* Cocotb 
* QuestaSim/ModelSim
* RISC-V Toolchain
* Spike
* Expect

## Quick start

To test your C code in this project, run in directory `/sim/`:

```bash
make build PROG_NAME=<your_program.c> && make sim
```
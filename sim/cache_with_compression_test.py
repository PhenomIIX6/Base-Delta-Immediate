import cocotb
from pathlib import Path
from cocotb.triggers import Timer, RisingEdge
import random
from spike_parser import *

clk_period = 10 
compression_ratio = 0
spike_log_path = Path(__file__).resolve().parent / "spike_log.log"

#clock generate
async def clk_generate(dut, clk_period):
    for _ in range(1000000):
        dut.clk.value = 0
        await Timer(clk_period / 2, units = 'ns')
        dut.clk.value = 1
        await Timer(clk_period / 2, units = 'ns')

#reset generate
async def rst_generate(dut, clk_period):
    dut.rst.value = 0
    await Timer(clk_period + clk_period/2, units='ns')
    dut.rst.value = 1

#load memory random data
async def memory_random_load(dut):
    for i in range(65536):
        if random.randint(1, 100) > 50:
            dut.main_memory.mem[i].value = random.randint(0, 16)
        else:
            dut.main_memory.mem[i].value = random.randint(0, 1000)

async def wait_correct_rdata(dut):
    await RisingEdge(dut.clk)
    while(dut.cache_hit.value == 0):
        await RisingEdge(dut.clk)
    assert str(dut.rdata.value) == str(dut.main_memory.mem[dut.address.value >> 2].value), f"In memory from addr {dut.address.value} other data than in rdata. \n In RDATA {dut.rdata.value}, but in memory {dut.main_memory.mem[dut.address.value >> 2].value}"

async def wait_write_en(dut):
    await RisingEdge(dut.clk)
    while(dut.cache_controller.memory_write_en == 0):
        await RisingEdge(dut.clk)

async def compression_ratio(dut):
    compression_count = 0
    total_cacheline = 0
    for i in range(1024):
        if (dut.cache.cache.value[i])[0] == 1 and (dut.cache.cache.value[i])[1] == 1:
            compression_count += 1
        if (dut.cache.cache.value[i])[0] == 1 and (dut.cache.cache.value[i])[1] == 1:
            total_cacheline += 1
    compression_rate = compression_ratio / compression_count
    return compression_rate

# @cocotb.test()
# async def random_test_two_line(dut):
#     await memory_random_load(dut)
#     cocotb.start_soon(clk_generate(dut, clk_period))
#     cocotb.start_soon(rst_generate(dut, clk_period))
#     for _ in range(600):
#         dut.address.value = random.randint(0, 15) 
#         dut.op_rd.value = 1
#     for _ in range(600):
#         dut.address.value = random.randint(16, 46)
#         dut.op_rd.value = 1
#         await wait_correct_rdata(dut)
#     for _ in range(600):
#         dut.address.value = random.randint(0, 46)
#         dut.op_rd.value = 1
#         await wait_correct_rdata(dut)
#     for _ in range(600):
#         dut.address.value = random.randint(0, 46)
#         dut.op_rd.value = 0
#         dut.wdata.value = random.randint(-1000, 1000)
#         await wait_write_en(dut)
#         await wait_write_en(dut)
#     for _ in range(600):
#         dut.address.value = random.randint(0, 46)
#         dut.op_rd.value = 1
#         await wait_correct_rdata(dut)
#     for _ in range(600):
#         dut.address.value = random.randint(0, 46)
#         dut.op_rd.value = random.randint(0, 1)
#         dut.wdata.value = random.randint(-1000, 1000)
#         await RisingEdge(dut.clk)
#         await RisingEdge(dut.clk)

# @cocotb.test()
# async def full_random_test(dut):
#     await memory_random_load(dut)
#     cocotb.start_soon(clk_generate(dut, clk_period))
#     cocotb.start_soon(rst_generate(dut, clk_period))
#     for i in range(10000):
#         dut.address.value = i
#         dut.op_rd.value = 1
#         await wait_correct_rdata(dut)
#     for i in range(10000):
#         dut.address.value = i
#         dut.op_rd.value = 0
#         dut.wdata.value = i
#         await wait_write_en(dut)
#     for i in range(10000):
#         dut.address.value = i
#         dut.op_rd.value = 1
#         await wait_correct_rdata(dut)
#     for i in range(20, 10000):
#         dut.address.value = i + random.randint(-10, 10)
#         dut.wdata.value = i * 3
#         dut.op_rd.value = 0
#         await wait_write_en(dut)
#         dut.address.value = i + random.randint(-10, 10)
#         dut.op_rd.value = 1
#         await wait_correct_rdata(dut)

@cocotb.test() 
async def real_test(dut):
    cocotb.start_soon(clk_generate(dut, clk_period))
    cocotb.start_soon(rst_generate(dut, clk_period))
    parsed = parse_spike_log_file(spike_log_path)
    for entry in parsed:
        dut.address.value = entry['address'] % (2**27)
        if entry['comand'] == 'sw':
            dut.op_rd.value = 0
            dut.wdata.value = entry['value']
            await wait_write_en(dut)
        else:
            dut.op_rd.value = 1
            await wait_correct_rdata(dut)
    print(compression_ratio(dut))
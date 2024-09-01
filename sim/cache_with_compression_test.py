import cocotb
from pathlib import Path
from cocotb.triggers import Timer, RisingEdge
import random

clk_period = 10

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
async def memory_load(dut):
    for i in range(0, 2 ** 15 + 1):
        dut.main_memory.mem[i].value = random.randint(-10000, 10000)

async def wait_correct_rdata(dut):
    await RisingEdge(dut.clk)
    while(dut.cache_hit.value == 0):
        await RisingEdge(dut.clk)
    assert str(dut.rdata.value) == str(dut.main_memory.mem[dut.address.value >> 2].value), f"In memory from addr {dut.address.value} other data than in rdata. \n In RDATA {dut.rdata.value}, but in memory {dut.main_memory.mem[dut.address.value >> 2].value}"

async def wait_write_en(dut):
    await RisingEdge(dut.clk)
    while(dut.cache_controller.memory_write_en == 0):
        await RisingEdge(dut.clk)

# async def cache_hit_rate(dut):
#     cocotb.log.info("Cache hit rate: %f" % cache_hit_rate)

#@cocotb.test()
async def random_test_two_line(dut):
    await memory_load(dut)
    cocotb.start_soon(clk_generate(dut, clk_period))
    cocotb.start_soon(rst_generate(dut, clk_period))
    for _ in range(600):
        dut.address.value = random.randint(0, 15) 
        dut.op_rd.value = 1
    for _ in range(600):
        dut.address.value = random.randint(16, 46)
        dut.op_rd.value = 1
        await wait_correct_rdata(dut)
    for _ in range(600):
        dut.address.value = random.randint(0, 46)
        dut.op_rd.value = 1
        await wait_correct_rdata(dut)
    for _ in range(600):
        dut.address.value = random.randint(0, 46)
        dut.op_rd.value = 0
        dut.wdata.value = random.randint(-1000, 1000)
        await wait_write_en(dut)
    for _ in range(600):
        dut.address.value = random.randint(0, 46)
        dut.op_rd.value = 1
        await wait_correct_rdata(dut)
    for _ in range(600):
        dut.address.value = random.randint(0, 46)
        dut.op_rd.value = random.randint(0, 1)
        dut.wdata.value = random.randint(-1000, 1000)
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

@cocotb.test()
async def full_random_test(dut):
    await memory_load(dut)
    cocotb.start_soon(clk_generate(dut, clk_period))
    cocotb.start_soon(rst_generate(dut, clk_period))
    for _ in range(20000):
        dut.address.value = random.randint(0, 2 ** 17)
        dut.op_rd.value = 1
        await wait_correct_rdata(dut)
    # for _ in range(10000):
    #     dut.address.value = random.randint(0, 2 ** 15)
    #     dut.op_rd.value = 0
    #     dut.wdata.value = random.randint(-1000, 1000)
    #     await wait_write_en(dut)
    # for _ in range(10000):
    #     dut.address.value = random.randint(0, 2 ** 15) 
    #     dut.op_rd.value = 1
    #     await wait_correct_rdata(dut)
    # await cache_hit_rate(dut)
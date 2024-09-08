from cocotb.runner import get_runner
from pathlib import Path
import os

if __name__ == "__main__":
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "questa")
    gui = os.getenv("GUI", "True")

    proj_path = Path(__file__).resolve().parent.parent

    verilog_sources = []
    vhdl_sources = []

    if hdl_toplevel_lang == "verilog":
        verilog_sources = [proj_path / "rtl" / "cache_controller.sv",
                           proj_path / "rtl" / "cache.sv",
                           proj_path / "rtl" / "little_compressor.sv",
                           proj_path / "rtl" / "compressor.sv",
                           proj_path / "rtl" / "little_decompressor.sv",
                           proj_path / "rtl" / "decompressor.sv",
                           proj_path / "rtl" / "lru.sv",
                           proj_path / "rtl" / "main_memory.sv",
                           proj_path / "rtl" / "system_with_compression.sv"]

    runner = get_runner(sim)

    runner.build(
    verilog_sources = verilog_sources,
    vhdl_sources = vhdl_sources,
    hdl_toplevel = "system_with_compression",
    always = True,
    )

    runner.test(
    hdl_toplevel = "system_with_compression",
    test_module = "cache_with_compression_test",
    waves = True,
    gui = gui,
    )

import subprocess
import sys

# Path to the src directory
SRC_DIR = "../../src"
TESTBENCH_FILE = "KnightsTour_tb.sv"  # Testbench file in the same folder as the script

# Compile the design and testbench files
def compile_verilog_files():
    try:
        # Compile all .sv files in the src folder and the testbench file
        subprocess.run(f"vlog {SRC_DIR}/*.sv {TESTBENCH_FILE}", shell=True, check=True)
        print(f"Compiled all .sv files in {SRC_DIR} and {TESTBENCH_FILE} successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error during compilation: {e}")
        sys.exit(1)

# Run the simulation without optimization and without coverage
def run_simulation():
    testbench_module = "KnightsTour_tb"
    try:
        subprocess.run([
            "vsim",
            "-c",
            "-do", "run -all; quit",
            testbench_module
        ], check=True)
        print("Simulation completed successfully (no optimization, no coverage).")
    except subprocess.CalledProcessError as e:
        print(f"Error during simulation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    print("Starting Verilog compilation and simulation...")

    # Compile the Verilog files
    compile_verilog_files()

    # Run the simulation
    run_simulation()

    print("All tasks completed successfully.")

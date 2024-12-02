import subprocess
import sys

"""
This script automates the compilation and simulation of Verilog files.

1. It compiles all Verilog source files in the specified src directory and the testbench file.
2. It runs the simulation using the specified testbench file in command-line mode without optimization or coverage.
3. Please ssh into the CAE machines before running the script

The following are the main components:

- SRC_DIR: Path to the directory containing Verilog source files.
- TESTBENCH_FILE: The name of the Verilog testbench file.
- compile_verilog_files(): Function to compile the Verilog files.
- run_simulation(): Function to run the simulation using ModelSim.

Error handling: If compilation or simulation fails, the script will terminate with an error message.
Run the script : python3 tb.py
"""

# Path to the src directory containing Verilog source files
SRC_DIR = "../../src"

# Testbench file in the same directory as this script
TESTBENCH_FILE = "KnightsTour_tb.sv"  # Testbench file in the same folder as the script

# Compile the design and testbench files
def compile_verilog_files():
    try:
        # Compile all .sv files in the src directory and the testbench file
        subprocess.run(f"vlog {SRC_DIR}/*.sv {TESTBENCH_FILE}", shell=True, check=True)
        print(f"Compiled all .sv files in {SRC_DIR} and {TESTBENCH_FILE} successfully.")
    except subprocess.CalledProcessError as e:
        # Print error message and terminate the script if compilation fails
        print(f"Error during compilation: {e}")
        sys.exit(1)

# Run the simulation without optimization and without coverage
def run_simulation():
    # Specify the testbench module to run
    testbench_module = "KnightsTour_tb"
    try:
        # Run the simulation using the vsim command with no optimization or coverage
        subprocess.run([
            "vsim",  # Command to start the simulator
            "-c",  # Run in command-line mode
            "-do", "run -all; quit",  # Execute the simulation and then quit
            testbench_module  # Specify the testbench module to run
        ], check=True)
        print("Simulation completed successfully (no optimization, no coverage).")
    except subprocess.CalledProcessError as e:
        # Print error message and terminate the script if simulation fails
        print(f"Error during simulation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    # Print a message to indicate the start of the Verilog compilation and simulation process
    print("Starting Verilog compilation and simulation...")

    # Call the function to compile Verilog files
    compile_verilog_files()

    # Call the function to run the simulation
    run_simulation()

    # Print a message indicating that all tasks were completed successfully
    print("All tasks completed successfully.")

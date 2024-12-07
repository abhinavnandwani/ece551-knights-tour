import subprocess
import sys

"""
This script automates the compilation, simulation, and coverage reporting for Verilog files.

1. It compiles all Verilog source files in the specified src directory and the testbench file.
2. It runs the simulation using the specified testbench file with coverage options enabled.
3. It generates a detailed coverage report in text format after simulation.
4. Please ssh into the CAE machines before running the script.

Run the script: python3 tb.py
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
        print(f"Error during compilation: {e}")
        sys.exit(1)

# Run the simulation with advanced coverage options
def run_simulation(testbench_module):
    ucdb_file = f"{testbench_module}.ucdb"
    try:
        # Run the simulation with coverage options and save the coverage data
        subprocess.run([
            "vsim",  # Start ModelSim simulator
            "-c",  # Command-line mode
            "-coverage",  # Enable coverage
            "-cvgperinstance",  # Enable per-instance coverage
            "-do", f"coverage save -onexit {ucdb_file}; run -all; quit",  # Save coverage to UCDB file
            testbench_module
        ], check=True)
        print(f"Simulation completed successfully with coverage saved to {ucdb_file}.")
    except subprocess.CalledProcessError as e:
        print(f"Error during simulation: {e}")
        sys.exit(1)
    return ucdb_file

# Generate a detailed coverage report using the UCDB file
def generate_coverage_report(ucdb_file):
    report_file = f"{ucdb_file.split('.')[0]}.txt"
    try:
        # Generate a coverage report using the UCDB file
        subprocess.run([
            "vsim",  # Start ModelSim
            "-c",  # Command-line mode
            "-viewcov", ucdb_file,  # Open the UCDB coverage file
            "-do", f"coverage report -file {report_file} -detail -option -cvg; quit -f"
        ], check=True)
        print(f"Detailed coverage report generated successfully: {report_file}")
    except subprocess.CalledProcessError as e:
        print(f"Error during coverage report generation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    print("Starting Verilog compilation, simulation, and coverage reporting...")

    # Compile Verilog files
    compile_verilog_files()

    # Define the testbench module name
    testbench_module = "KnightsTour_tb2"

    # Run the simulation and get the UCDB file
    ucdb_file = run_simulation(testbench_module)

    # Generate a detailed coverage report
    generate_coverage_report(ucdb_file)

    print("All tasks completed successfully.")

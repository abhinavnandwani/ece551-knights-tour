import os
import subprocess
import sys

# Compile the design and testbench files
def compile_verilog_files(design_file, testbench_file):
    try:
        # Compile without specifying the work library
        subprocess.run(["vlog", design_file, testbench_file], check=True)
        print(f"Compiled {design_file} and {testbench_file} successfully.")

        # Compile into the work library
        subprocess.run(["vlog", "-work", "work", design_file, testbench_file], check=True)
        print(f"Compiled {design_file} and {testbench_file} into the work library.")
    except subprocess.CalledProcessError as e:
        print(f"Error during compilation: {e}")
        sys.exit(1)

# Run the simulation
def run_simulation(testbench_module):
    try:
        subprocess.run(["vsim", "-c", "-do", "run -all; quit", testbench_module], check=True)
        print("Simulation completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error during simulation: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python3 run_verilog.py <design_file> <testbench_file> <testbench_module>")
        sys.exit(1)

    design_file = sys.argv[1]
    testbench_file = sys.argv[2]
    testbench_module = sys.argv[3]

    print("Starting Verilog compilation and simulation...")

    # Compile the Verilog files
    compile_verilog_files(design_file, testbench_file)

    # Run the simulation
    run_simulation(testbench_module)

    print("All tasks completed.")
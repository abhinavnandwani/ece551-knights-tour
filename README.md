# Knight's Tour Project

## Overview
This project implements the Knight’s Tour algorithm, utilizing a digital system built in Verilog. The design is synthesized for an FPGA, allowing a chessboard’s knight piece to autonomously navigate across the board in a specific pattern. The project includes multiple hardware modules (SPI, IR sensors, UART, and motor control), and is verified using ModelSim and Synopsys synthesis tools.


## Project Structure
The project is organized as follows:
- **`KnightsTour.sv`** - Top-level Verilog file defining the core design for the Knight’s Tour.
- **`KnightsTour_tb.sv`** - Optional testbench template file for verifying design functionality.
- **`KnightPhysics.sv`** - Model simulating the physics of the knight on the chessboard.
- **Other Modules**:
  - `SPI_iNEMO4.sv`: Inertial sensor model.
  - `inertial_integrator.sv`: Processes inertial data for synthesis.
  - `IR_intf.sv`: Interface for IR sensors.

## Design Overview
The system consists of multiple interconnected modules to control the knight’s movement on the chessboard:
- **Gyro Interface**: SPI-based module to communicate with the gyro sensor.
- **BLE Module**: Handles UART-based Bluetooth communication.
- **IR Sensors**: Detect obstacles and measure movement.
- **PID Control**: Adjusts movement speed and direction.
- **PWM Signals**: Drives motors for precise positioning.

## Modules and Interfaces
### Core Signals
| Signal Name | Direction | Description |
|-------------|-----------|-------------|
| `clk`       | Input     | 50MHz clock signal. |
| `RST_n`     | Input     | Active-low reset signal. |
| `MISO`      | Input     | SPI data in from gyro. |
| `SS_n`      | Output    | Active-low select for gyro. |
| `SCLK`      | Output    | SPI clock for gyro. |
| `MOSI`      | Output    | SPI data out to gyro. |
| `RX`        | Input     | UART data in from BLE module. |
| `TX`        | Output    | UART data out to BLE module. |
| `lftPWM1, lftPWM2` | Output | PWM for left motor control. |
| `rghtPWM1, rghtPWM2` | Output | PWM for right motor control. |

### Provided Modules
- **`KnightPhysics.sv`**: Simulates the knight’s movement on the chessboard.
- **`SPI_iNEMO4.sv`**: Models the inertial sensor interface.
- **`IR_intf.sv`**: Conditions IR sensor inputs for obstacle detection.

## Synthesis Details
The design must meet specific synthesis requirements:
- **Target Frequency**: 333MHz (for standard cell mapping; 50MHz for FPGA).
- **Constraints**:
  - Input delay: 0.4ns after clock rise.
  - Output delay: 0.4ns before next clock rise.
  - Max transition time: 0.15ns.
  - Clock uncertainty: 0.15ns.
- **Optimization**: Area reduction prioritized over timing; target area is 16,242 units.



## Extra Credit
Additional points can be earned by achieving code coverage:
- **1%**: Run code coverage on a single test.
- **2%**: Achieve cumulative coverage across the test suite.
- **3%**: Use coverage results to improve the test suite with documented changes.

---

# vhdl-simple-processor
Design and simulation of a simple FSM-based processor in VHDL.

This project presents the design and simulation of a minimal processor architecture developed in VHDL as part of a digital systems laboratory project. The objective is to model a simple processor including a datapath, a control unit based on a finite state machine, and a basic instruction set.

---

## 📌 Project Overview

The project focuses on the incremental design of a simple 9-bit processor, implemented in two main versions:

- **Version 1**: Standalone processor with manual instruction input
- **Version 2**: Autonomous processor with program counter and ROM memory

Each version was validated through simulation to ensure correct execution of the supported instructions.

---

## 🏗️ Processor Architecture

The processor architecture is composed of:
- Eight general-purpose registers (R0 to R7)
- An instruction register (IR)
- An arithmetic logic unit supporting addition and subtraction
- A shared internal bus
- A control unit implemented as a Moore finite state machine
- A multiplexer using one-hot encoding to select bus sources

In version 2, the processor is extended with:
- A program counter
- A ROM memory storing a sequence of instructions
- Automatic instruction fetching and execution

---

## ⚙️ Instruction Set

The supported instruction set includes:

| Instruction | Description |
|-------------|-------------|
| `mv Rx, Ry` | Copy the contents of register Ry into register Rx |
| `mvi Rx, #D` | Load immediate value D into register Rx |
| `add Rx, Ry` | Add the contents of Ry to Rx |
| `sub Rx, Ry` | Subtract the contents of Ry from Rx |

---

## 🧩 Project Structure

vhdl-simple-processor/
│
├── README.md
│
├── src/
│ ├── v1/
│ │ ├── proc.vhd -- Processor (version 1)
│ │ ├── registre.vhd -- Generic register
│ │ ├── mux.vhd -- Bus multiplexer
│ │ ├── add_sub.vhd -- Adder/Subtractor
│ │ └── dec3to8.vhd -- Decoder
│ │
│ └── v2/
│ ├── proc_v2.vhd -- Processor (version 2)
│ ├── counter.vhd -- Program counter
│ └── memory.vhd -- ROM memory


---

## 🔁 Control Unit

The control unit is implemented as a finite state machine (FSM) with four states:

- `T0`: Instruction fetch
- `T1`: Operand preparation or execution
- `T2`: Arithmetic execution (if required)
- `T3`: Result write-back

Each instruction is executed over one or multiple clock cycles depending on its type.

---

## 🧪 Simulation & Validation

The design has been validated using ModelSim simulations:
- Individual components were tested independently
- The complete processor behavior was verified for both versions
- Simulation waveforms confirm correct execution of all supported instructions

In version 2, a full program stored in ROM is executed automatically, demonstrating correct instruction sequencing and data manipulation.

---

## ⏱️ Clocking Strategy

Although the initial specification distinguishes between processor and memory clocks, this implementation uses a single clock to synchronize the entire system (processor, counter, and memory). This choice simplifies integration and ensures reliable simulation behavior.

---

## 🚧 Limitations

- Limited instruction set
- No branching or jump instructions
- No pipeline or parallel execution
- Fixed data width (9 bits)
- A third version was planned but could not be implemented due to time constraints

---

## 📚 Tools Used

- VHDL
- ModelSim (simulation)
- Git and GitHub (version control)

---

## 🎓 Context

This project was developed as part of a university laboratory assignment in digital systems design, focusing on processor architecture, FSM-based control, and structural VHDL modeling.

---

## 👤 Author

**Emre BEF**  

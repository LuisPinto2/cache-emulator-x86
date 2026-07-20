# x86-64 NASM Cache Emulator

A robust, low-level cache memory simulator written in x86-64 NASM Assembly. This project emulates a direct-mapped cache architecture and strictly adheres to standard Linux ABI conventions.

<p align="center">
  <img src="img/exec_demo.gif" alt="Cache Emulator Demonstration" width="750">
</p>

> **Academic Context & Portfolio Migration:** Developed in 2024 as a core engineering project for the **Computer Systems Architecture** (_Arquitetura de Sistemas Computacionais_) course, within the BSc in Software Engineering program at the **Faculty of Sciences of the University of Lisbon** (FCUL). The code was migrated and re-factored for this repository in July 2026 to ensure long-term portfolio preservation, clean documentation, and compliance with industry standards.

## Technical Specifications

- **Architecture:** Direct-mapped cache simulation.
- **Addressing:** 16-bit physical addresses decomposed into:
    - 10-bit Tag
    - 4-bit Index
    - 2-bit Offset
- **ABI Compliance:** Fully compliant with the System V AMD64 ABI, ensuring strict 16-byte stack alignment and meticulous preservation of callee-saved registers (`r12`-`r15`).
- **Memory Management:** Implements precise bit-masking and bit-shifting operations to isolate address components and prevent data contamination across execution cycles.

## Engineering Challenges & Optimizations

Building a low-level simulator in raw Assembly requires control over hardware resources. During development, several critical systems-level challenges were tackled:

- **Strict System V ABI Compliance:** Ensured that the 16-byte stack alignment rule was meticulously maintained before any external function calls. Callee-saved registers (`r12` to `r15`) were protected and used for state persistence across execution cycles.
- **State Optimization & Control Flow:** Re-engineered the conditional branch logic to handle multi-argument processing efficiently. Shifted critical execution loop counters from volatile registers to callee-saved registers (`r14`, `r15`), successfully resolving segmentation faults and avoiding redundant system calls.
- **Memory Isolation:** Implemented precise bit-masking operations (isolating the 10-bit tag, 4-bit index, and 2-bit offset) to strictly prevent any data contamination within the simulated direct-mapped structure.

## Architectural Requirements & Implementation Decisions

The architectural specifications for this emulator were guided by the course requirements, focusing on implementing a hardware-accurate model using software constraints.

### 1. Cache Constraints & Specifications (Project Requirements)

The emulator adheres strictly to the architectural design defined in the project specification:

- **Direct-Mapped Cache:** A hardware-accurate model where each physical memory address maps to a single cache line.
- **Address Space:** A 16-bit address layout, segmented into a **10-bit Tag** (block identification), a **4-bit Index** (mapping to the $2^4 = 16$ cache slots), and a **2-bit Offset** (identifying the specific byte within a 4-byte block).

### 2. Low-Level Implementation Decisions (Developer's Design)

While the structural constraints were predefined, the logic to handle them was custom-engineered at the processor level to optimize performance and stability:

- **Bit-Masking & Bit-Shifting:** To cleanly isolate the address subcomponents without high-level abstractions, logical masks (`AND` operations with specific hexadecimal values) and bitwise right-shifts (`SHR`) were implemented to extract and realign the _Tag_ and _Index_ fields efficiently.
- **Strict System V AMD64 ABI Compliance:** Because the project required integration with a proprietary pre-compiled external object (`biblioteca.o`), exceptional care was taken to maintain standard Linux x86-64 calling conventions. This involved manually safeguarding _callee-saved_ registers (`r12` - `r15`) via the _Stack_ and strictly enforcing a 16-byte _Stack_ alignment prior to execution loops to eliminate any risk of runtime segmentation faults.

## Technical Challenges & Resolution

### 1. Pointer Arithmetic and Array Offsets in Assembly

- **The Problem:** Accessing specific cache lines and fields required manual byte-offset calculations based on the structural size of each cache line entry.
- **The Resolution:** Implemented effective address calculations using scaled indexing (e.g., `[base + index * scale]`) to calculate automatically target memory locations without adding overhead cycles.

### 2. Black-Box Integration & Iterative Debugging

- **The Problem:** Linking with the proprietary, pre-compiled `biblioteca.o` meant that the internal execution was completely opaque. Without access to the library's source code, early logic bugs or subtle stack misalignments were difficult to track using standard debugging methods.
- **The Resolution:** Resolved this through a highly iterative process. By making incremental code changes, running the execution cycles, and closely observing how the application responded to different memory inputs over time, I systematically isolated bugs and aligned my Assembly logic with the library's requirements.

## Project Structure

```text
cache-emulator-x86/
├── img/
│   └── exec_demo.gif             # Visual execution preview
├── src/
│   └── cache-emulator-x86.asm    # Core emulator logic and ABI interface
├── .gitignore                    # Build and environment exclusions
└── README.md                     # Project documentation
```

## Compilation and Execution

This project relies on a proprietary university object file (`biblioteca.o`) which provided the core back-end.

To comply with FCUL's intellectual property guidelines, this file is not included. Therefore, the repository serves as a **code showcase** and cannot be compiled out-of-the-box without the university's environment.

```bash
# Assemble the source code
nasm -f elf64 -g -F dwarf src/cache-emulator-x86.asm -o cache_emulator.o

# Link with the external library
gcc -no-pie cache_emulator.o biblioteca.o -o cache_emulator -nostartfiles -fPIE -no-pie -lncurses

# Run the emulator (Example)
./cache_emulator Bb @b
```

### Controls & Simulation Flow

**Advance/Exit**: Press `q` to progress through the memory access cycles.

## Automated Verification & Trace Logs

The emulator outputs an execution trace (`operation_log.txt`) matching the simulation runtime metrics. This log captures the sequential state machine transitions for each memory access cycle, detailing the Cache Index, decoded Tag values, and the Hit/Miss outcome status:

```text
Operation | Index | Tag   | Status/Result
-----------------------------------------
3         | 13    | 99    | 99    (Cycle Start)
2         | 13    | 99    | 99    (Tag Evaluation)
5         | 13    | 393   | 99    (Target Address Decoded)
1         | 13    | 99    | 2     (Cache Miss - Allocation)
```

This deterministic logging ensures the core Assembly logic can be thoroughly tested and verified against expected architectural hardware behavior.

## Academic Integrity Notice

**Note on Academic Integrity & IP**: The external object file (`biblioteca.o`) is omitted from this repository to protect intellectual property guidelines and strictly comply with university academic policies.

This repository is published purely for portfolio and educational demonstration purposes.

- **For current students**: While the _MIT License_ legally grants permission to modify and distribute this software, using or reproducing any part of this code for official academic assignments strictly violates the Academic Integrity Regulations of the Faculty of Sciences of the University of Lisbon (FCUL) and constitutes plagiarism.
- The author holds no responsibility for any misuse or academic misconduct committed by third parties.

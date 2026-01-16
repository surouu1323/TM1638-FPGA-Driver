# **TM1638 FPGA Driver – Tang Nano 20K**

## 📌 Overview

This project implements a **TM1638 LED & button driver** on **FPGA**, supporting:

* 8-digit **7-segment display**
* **Discrete LEDs**
* **Button scanning**
* Gated serial clock generation using a dedicated clock-enable cell

The design has been **implemented and tested on Tang Nano 20K FPGA** with a real TM1638 module.

---

## 🧩 Architecture

The system consists of the following main components:

* **Top module**

  * Generates **1 MHz clock** from input clock using **PLL**
  * Handles reset and button registering
  * Connects all submodules

* **TM1638 Driver**

  * FSM-based controller
  * Serial data transfer via **DIO / SCLK / CS_n**
  * Supports display update and key scan

* **Counter Module**

  * Generates flattened **7-segment data** for display test

---

## ⏱ Clocking

* Input clock → PLL
* Output clocks:

  * **24 MHz** (unused)
  * **1 MHz** (used for TM1638 interface)
* **SCLK** is generated using a **gated clock** via an external clock-enable cell

---

## 🔌 Hardware Platform

* **FPGA board:** Tang Nano 20K
* **Peripheral:** TM1638 LED & Button Module
* **Interface signals:**

  * `SCLK` – Serial clock
  * `CS_n` – Chip select (active low)
  * `DIO` – Bidirectional data line

---

## 📁 Project Structure

```text
.
├── rtl/
│   ├── top.v          # Top-level module
│   ├── tm1638.v       # TM1638 driver
│   ├── counter.v      # 7-segment data generator
│   └── pll.v          # PLL IP
├── constraint/
│   └── tang_nano_20k.cst
└── README.md
```

---

## ▶️ How It Works

1. PLL generates a **1 MHz clock** from the board clock
2. TM1638 driver initializes display settings
3. 7-segment display shows counter values
4. Button states are read from TM1638
5. Button data is reflected on the discrete LEDs

---

## 🧪 Verification & Testing

* **FPGA-level testing** with real TM1638 module
* Verified:

  * Display control
  * LED update
  * Button scanning
* Clock gating validated on hardware

---

## 🛠 Tools

* **FPGA:** Tang Nano 20K
* **HDL:** Verilog
* **Toolchain:** Gowin IDE

---

## 🚀 Future Improvements

* Add brightness control via register
* Support TM1638 auto-increment / fixed address modes
* Migrate clock gating to fully integrated cell

---

👉 cứ nói nhé 👍

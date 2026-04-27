# DE1 Projekt – Generátor priebehov (úloha 2)
### Platforma: Nexys A7-50T | Jazyk: VHDL | Nástroj: Vivado

# Obsah:
## [Štruktúra projektu](https://github.com/qubbo1/DE1_Projekt_uloha2#%C5%A1trukt%C3%BAra-projektu-1)
## [🔧 Architecture Overview](https://github.com/qubbo1/DE1_Projekt_uloha2#-architecture-overview-1)
## [Popis priebehov](https://github.com/qubbo1/DE1_Projekt_uloha2#popis-priebehov-1)
## [Ovladanie](https://github.com/qubbo1/DE1_Projekt_uloha2#ovladanie-1)
## [Simulácie](https://github.com/qubbo1/DE1_Projekt_uloha2/blob/main/README.md#simul%C3%A1cie)

---
## Štruktúra projektu

```
DE1_Projekt_uloha2/
├── src/
│   ├── square_wave_gen.vhd   ← Generátor obdĺžnika 
│   ├── pwm_gen.vhd           ← 8-bit PWM modul 
│   ├── seg7_ctrl.vhd         ← Ovládač 7-seg displeja 
│   └── top.vhd               ← Vrchná entita 
├── sim/
│   └── tb_square_wave_gen.vhd ← Testbench pre square_wave_gen
└── constraints/
    └── nexys_a7_50t.xdc      ← Pin constraints
```
## 🔧 Architecture Overview



| Module | Description |
|---|---|
| **Clock Enable** | Delenie hodinového signálu na pracovnú frekvenciu |
| **Debouncer** | Ošetrenie zákmitov tlačidiel (SW debouncing) |
| **Control Logic** | Riadenie výberu vlnového tvaru | --preklik na simulaciu--
| **Integrátor** | Čítač/akumulátor – generuje obdĺžnik a trojuholník | --preklik na simulaciu--
| **Komparátor** | Porovnáva s `up_limit` a `down_limit`, prepína smer integrácie | --preklik na simulaciu--
| **LUT** | Tabuľka hodnôt pre sínus (DDS princíp) | --preklik na simulaciu--
| **Tune Switch (MUX)** | Výber medzi obdĺžnikom, píla/trojuholník, sínus – 1 tlačidlo, 3 režimy | --preklik na simulaciu--
| **Digital Amp** | Digitálne zosilnenie výstupného signálu | --preklik na simulaciu--
| **DAC** | Výstup na osciloskopu cez Pmod DA2 | --preklik na simulaciu--

# Waveform Generator — VHDL Component Reference

| Component | Signal Name | Direction | VHDL Type | Vector Size | Signal Description | Component Function |
|-----------|-------------|-----------|-----------|-------------|--------------------|--------------------|
| clk_en | clk | in | std_logic | — | 100 MHz system clock | Generic clock-enable generator. Outputs a single-cycle pulse every G_MAX clock cycles. Default G_MAX=1,000,000. Used by debounce with G_MAX=200,000 → 2 ms sampling at 100 MHz. |
|  | rst | in | std_logic | — | Synchronous active-high reset |  |
|  | ce | out | std_logic | — | Single-cycle enable pulse |  |
| debounce | clk | in | std_logic | — | 100 MHz system clock | Button debounce and edge detector. Synchronises raw input, samples every 2 ms via clk_en, requires 4 consecutive identical samples. Outputs stable level, one-cycle press pulse, one-cycle release pulse. |
|  | rst | in | std_logic | — | Synchronous active-high reset |  |
|  | btn_in | in | std_logic | — | Raw bouncy button input |  |
|  | btn_state | out | std_logic | — | Debounced stable level |  |
|  | btn_press | out | std_logic | — | One-cycle pulse on press (rising edge) |  |
|  | btn_release | out | std_logic | — | One-cycle pulse on release (falling edge) |  |
| control_logic | clk | in | std_logic | — | 100 MHz system clock | Menu controller. SW[0]=1,SW[1]=0 → frequency mode: BTNU/BTND change digit at cursor, BTNR/BTNL move cursor. SW[1]=1,SW[0]=0 → waveform mode: BTNU/BTND cycle waveform. Outputs binary freq (0–9999 Hz), 2-bit wave select, and 64-bit display word. |
|  | rst | in | std_logic | — | Synchronous active-high reset |  |
|  | btn_u | in | std_logic | — | Debounced Up button pulse |  |
|  | btn_d | in | std_logic | — | Debounced Down button pulse |  |
|  | btn_l | in | std_logic | — | Debounced Left button pulse |  |
|  | btn_r | in | std_logic | — | Debounced Right button pulse |  |
|  | sw_freq | in | std_logic | — | SW[0] — frequency edit mode |  |
|  | sw_wave | in | std_logic | — | SW[1] — waveform select mode |  |
|  | freq_val | out | std_logic_vector | (13 downto 0) | Binary frequency 0–9999 Hz |  |
|  | wave_sel | out | std_logic_vector | (1 downto 0) | Waveform: 00=SQ 01=SIN 10=SAW 11=TRI |  |
|  | disp_data | out | std_logic_vector | (63 downto 0) | 8×8-bit display word for seg7_ctrl |  |
| phase_counter | clk | in | std_logic | — | 100 MHz system clock | DDS phase accumulator. Each clock cycle adds incr = freq_val × 43 to a 32-bit register. Upper 8 bits = phase output. Accuracy: f_out ≈ freq_val × 1.001 Hz (error < 0.12 %). freq_val=0 → phase frozen (DC). |
|  | rst | in | std_logic | — | Synchronous reset — clears accumulator |  |
|  | freq_val | in | std_logic_vector | (13 downto 0) | Target frequency in Hz (0–9999) |  |
|  | phase | out | std_logic_vector | (7 downto 0) | Current DDS phase 0–255 |  |
| sine_lut | addr | in | std_logic_vector | (7 downto 0) | Phase address 0–255 | Asynchronous 256-entry sine ROM. Values = round(127.5 + 127.5 × sin(2π×i/256)). Range: 0x00 (neg. peak) … 0x80 (mid) … 0xFF (pos. peak). Output valid in same cycle as address. |
|  | data_out | out | std_logic_vector | (7 downto 0) | Sine amplitude at given phase |  |
| square_gen | phase | in | std_logic_vector | (7 downto 0) | Phase input from phase_counter | Combinational 50 % duty-cycle square wave. phase[7]='1' → 0xFF; phase[7]='0' → 0x00. No clock or reset needed. |
|  | wave_out | out | std_logic_vector | (7 downto 0) | 0xFF (high half) or 0x00 (low half) |  |
| sawtooth_gen | phase | in | std_logic_vector | (7 downto 0) | Phase input 0–255 | Combinational rising sawtooth. Output = phase directly (0→255 linear ramp, instant reset). No clock or reset needed. |
|  | wave_out | out | std_logic_vector | (7 downto 0) | Sawtooth amplitude = phase |  |
| triangle_gen | phase | in | std_logic_vector | (7 downto 0) | Phase input from phase_counter | Combinational triangle wave. phase[7]='0' → output rises 0→254; phase[7]='1' → output falls 254→0. Symmetric, no sharp edges. No clock or reset needed. |
|  | wave_out | out | std_logic_vector | (7 downto 0) | Triangle amplitude 0x00–0xFE–0x00 |  |
| wave_mux | wave_sq | in | std_logic_vector | (7 downto 0) | Square wave sample | 4-to-1 combinational multiplexer. Selects one 8-bit waveform sample based on wave_sel. Default (others) → Square. |
|  | wave_sin | in | std_logic_vector | (7 downto 0) | Sine wave sample |  |
|  | wave_saw | in | std_logic_vector | (7 downto 0) | Sawtooth wave sample |  |
|  | wave_tri | in | std_logic_vector | (7 downto 0) | Triangle wave sample |  |
|  | wave_sel | in | std_logic_vector | (1 downto 0) | 00=SQ  01=SIN  10=SAW  11=TRI |  |
|  | wave_out | out | std_logic_vector | (7 downto 0) | Selected waveform output |  |
| pwm | clk | in | std_logic | — | 100 MHz system clock | 8-bit PWM at ≈390 kHz (100 MHz÷256). Counter 0–255 cycles each period; output HIGH while counter < sample. Drive RC low-pass → analogue waveform on AUX jack. |
|  | rst | in | std_logic | — | Synchronous active-high reset |  |
|  | sample | in | std_logic_vector | (7 downto 0) | Duty cycle: 0x00=0%  0x80=50%  0xFF≈100% |  |
|  | pwm_out | out | std_logic | — | PWM output signal (~390 kHz) |  |
| seg7_ctrl | clk | in | std_logic | — | 100 MHz system clock | Time-multiplexed 8-digit 7-seg controller. Cycles digits at 1 ms each (100,000 cycles) → ~125 Hz refresh per digit. Byte format: bit[7]=DP, bits[6:0]=segments (active-LOW). Byte 0=AN0 (rightmost). |
|  | rst | in | std_logic | — | Synchronous active-high reset |  |
|  | disp_data | in | std_logic_vector | (63 downto 0) | 8×8-bit display data (byte 0=AN0) |  |
|  | seg | out | std_logic_vector | (6 downto 0) | {CG,CF,CE,CD,CC,CB,CA} active-LOW |  |
|  | dp | out | std_logic | — | Decimal point, active-LOW |  |
|  | an | out | std_logic_vector | (7 downto 0) | Anode enables, one LOW active at a time |  |
| top<br>(wavegen_top) | CLK100MHZ | in | std_logic | — | 100 MHz board oscillator | Top-level structural entity (Nexys A7-50T). Connects all sub-components. BTNC=reset. SW[0]/SW[1]=control mode. SW[2]=AUX+JA enable. LED held '0'. AUD_PWM→RC→3.5 mm jack. JA[0]=wave MSB for oscilloscope. |
|  | BTNC | in | std_logic | — | Centre button → system reset |  |
|  | BTNU | in | std_logic | — | Up button |  |
|  | BTND | in | std_logic | — | Down button |  |
|  | BTNL | in | std_logic | — | Left button |  |
|  | BTNR | in | std_logic | — | Right button |  |
|  | SW | in | std_logic_vector | (15 downto 0) | Switches: [0]=freq [1]=wave [2]=AUX en. |  |
|  | LED | out | std_logic_vector | (15 downto 0) | LEDs — unused, driven '0' |  |
|  | SEG | out | std_logic_vector | (6 downto 0) | 7-seg segments (active-LOW) |  |
|  | DP | out | std_logic | — | Decimal point (active-LOW) |  |
|  | AN | out | std_logic_vector | (7 downto 0) | 7-seg anodes (active-LOW) |  |
|  | AUD_PWM | out | std_logic | — | PWM audio to AUX jack (gated SW[2]) |  |
|  | AUD_SD | out | std_logic | — | Audio amp enable = SW[2] |  |
|  | JA | out | std_logic_vector | (7 downto 0) | Pmod: JA[0]=wave MSB (SW[2]), rest '0' |  |


## Popis priebehov
| `wave_sel` | Skratka | Typ priebahu | Súbor / Popis |
|:----------:|---------|--------------|---------------|
| `00` | **SQr** | Square – obdĺžnikový | `square_gen.vhd` – 50 % duty cycle, skok 0 ↔ 255 |
| `01` | **SIn** | Sine – sínusový | `sine_lut.vhd` – 256-položková LUT, plná sínusoida |
| `10` | **SAu** | Sawtooth – pílový | `sawtooth_gen.vhd` – lineárny nábeh 0 → 255, potom skok na 0 |
| `11` | **trI** | Triangle – trojuholníkový | `triangle_gen.vhd` – nábeh 0 → 255 a späť 255 → 0 |

## Ovladanie
| Vstup       | Podmienka   | Funkcia                          |
|-------------|-------------|----------------------------------|
| `BTNU` ↑   | `SW(0)=1`   | Zvýšiť frekvenciu                |
| `BTND` ↓   | `SW(0)=1`   | Znížiť frekvenciu                |
| `BTNR` →   | `SW(1)=1`   | Ďalší vlnový tvar                |
| `BTNL` ←   | `SW(1)=1`   | Predchádzajúci vlnový tvar       |
| `BTNC`      | –           | Systémový reset                  |
| `SW(2)`     | –           | Povolenie AUX výstupu            |






## PWM výstup

**Pin:** `JA[0]` (Pmod JA, pin 1)

Pre analógový výstup pridáme RC dolnopriepustný filter:

(EXPERIMENTÁLNE)

```
JA[0] ──┤ R=1kΩ ├──┬── Výstup (osciloskop / DAC)
                   │
                 C=100nF
                   │
                  GND
```
## Simulácie



## Bloková Schéma

![Screenshot](./imgs/schemaV1.4.png)



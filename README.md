# DE1 Projekt – Generátor priebehov (úloha 2)
### Platforma: Nexys A7-50T | Jazyk: VHDL | Nástroj: Vivado

# Obsah:
## [Štruktúra projektu](https://github.com/qubbo1/DE1_Projekt_uloha2#%C5%A1trukt%C3%BAra-projektu-1)
## [🔧 Architecture Overview](https://github.com/qubbo1/DE1_Projekt_uloha2#-architecture-overview-1)
## [Popis priebehov](https://github.com/qubbo1/DE1_Projekt_uloha2#popis-priebehov-1)
## [Ovladanie](https://github.com/qubbo1/DE1_Projekt_uloha2#ovladanie-1)

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
| **Clock Divider** | Delenie hodinového signálu na pracovnú frekvenciu |
| **Debouncer** | Ošetrenie zákmitov tlačidiel (SW debouncing) |
| **Control Logic** | Riadenie výberu vlnového tvaru |
| **Integrátor** | Čítač/akumulátor – generuje obdĺžnik a trojuholník |
| **Komparátor** | Porovnáva s `up_limit` a `down_limit`, prepína smer integrácie |
| **LUT** | Tabuľka hodnôt pre sínus (DDS princíp) |
| **Tune Switch (MUX)** | Výber medzi obdĺžnikom, píla/trojuholník, sínus – 1 tlačidlo, 3 režimy |
| **Digital Amp** | Digitálne zosilnenie výstupného signálu |
| **DAC** | Výstup na osciloskopu cez Pmod DA2 |

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




## Bloková Schéma

![Screenshot](./imgs/schemaV1.4.png)



# DE1_Projekt_uloha2
## Úlohy:

# Hlavné bloky:
Clock enable – dělení hodinového signálu

Debounce – odstranění zakmitání tlačítka

Control logic – řízení counteru, komparátoru a MUXu (vnitřní mozek)

Integrátor (čítač/akumulátor) – vytváří trojúhelníkový průběh

Komparátor – porovnává dvě hodnoty na vstupu, výstupem je obdélníkový průběh signálu

LUT – tabulka s pamětí (obsahuje např. sinus, trojúhelník, pilu atd.), ze které vybíráme hodnotu podle adresy (DDS princíp)

MUX – digitální přepínač, který vybírá trojúhelník, sinus, pilu či jiný průběh, který máme definovaný

IO pin – fyzický port na FPGA desce (Nexys A7 50-T)

PWM – modul, který převádí digitální "vlnu" na 1bitový signál

RC filtr – vyhlazuje 1bitový signál z PWM na analogový signál

## Rozdelenie úloh
## Dodatky

## Prepis
Funkční generátor WaveGen (WaveFrom Generator) umožňuje generovat harmonický, trojúhelníkový a obdélníkový signál. V moderním pojetí umí WaveGen generovat signál libovolného průběhu, kdy se jedná o programovatelný DDS (Direct Digital Synthesis) generátor.

Náš WaveGen (zkráceně WG) má rozlišení 8 bitů a jeho architektura je následující: Clock Enable, Debounce, Control Logic, Counter, Comparator, IO pin, LUT, MUX, PWM a RC filtr.

Princip fungování celého designu je popsán v těchto bodech:

a)  Na vstupu WG máme vstupní clk signál, který napájí Debounce, Clock Enable, Control Logic, Counter a PWM. Dále vstup rst pro reset celého systému, a btn_in pro ovládání režimů a hodnot tlačítkem.

b) Debounce vyčistí zakmitání tlačítka a vytvoří btn_press (jednopulzní signál — klik) a btn_state (stabilní stav). My používáme jen btn_state, který jde do bloku Control Logic.

c) Control Logic rozhoduje, jaký průběh se má generovat, zda Counter počítá nahoru nebo dolů, zda je povolený, jaký je threshold pro komparátor, kdy se má resetovat counter. Generuje en_out (povolení čítače), dir_out (směr čítání), rst_out (reset čítače), sel_out (výběr vlny pro MUX) a threshold_out (práh pro komparátor).

d) Counter je časová základna celého generátoru,jehož výstup jde do LUT a komparátoru. Generuje adresy a trojúhelníkový průběh. Když Counter počítá nahoru, tak rampa (přímka) roste (směr integrace roste), pokud Counter čítá dolů, tak rampa klesá. Tím, že Control Logic přepíná směr Counteru, tak vzniká trojúhelníkový průběh. Control logic přepíná směr integrace na základě dosažení maximální nebo minimální hodnoty v Counteru (minimální hodnota je 0 a maximální hodnota je 255 — 2^8-1 je právě 255).

e) Komparátor porovnává hodnotu z Counteru a threshold z Control Logic. Když hodnota Counteru je větší než hodnota threshold, tak na výstupu komparátoru je logická 1, jinak je na výstupu logická 0. Odtud jdou výstupní hodnoty komparátoru do IO pinů FPGA desky, a pak na osciloskop (CH2) — obdélník.

f) LUT (Look-up-Table) je tabulka, která obsahuje 4096 hodnot sinusovky, takže když counter běží, tak LUT postupně vrací vzorky sinusovky.

g) Mux dostává na vstup sinus z LUT, trojúhelník z Counteru a DC úroveň. Podle sel_out vybere jeden z těchto průběhů (opět se uplatňuje řídicí logika).

h) PWM modul vezme signál z MUXU, kterou vybral, a vytvoří signál, jehož šířka pulzu odpovídá amplitudě (Pulse-Width Modulation).

i) RC filtr (dolní propust) zprůměruje šířku pulzu z PWM, odstraní vysdoké frekvence a vytvoří hladkou analogovou vlnu, kterou pouští na vstup osciloskopu (CH1). 






![Screenshot](./imgs/schemaV1.4.png)
![Screenshot](./imgs/schemaV1.1.png)
![Screenshot](./imgs/design.jpg)


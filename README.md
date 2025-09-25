# Monitor de Temperatura

## Nome

*   Mouzarthy Ferreira Soares


## Resumo

Este projeto em Verilog implementa um Monitor de Temperatura Ambiente utilizando um FPGA como processador central. 

Os componentes principais incluem:

Módulo de Comunicação I2C Master: Desenvolvido em Verilog, é responsável por inicializar e ler dados de temperatura do sensor BMP280.

Interface de Saída para Display de 7 Segmentos: Lógica de decodificação e multiplexação que exibe a temperatura aferida de forma clara e contínua.

O resultado é um sistema autônomo que lê a temperatura via protocolo serial I2C e a exibe em tempo real em um display de 7 segmentos, validando as habilidades de projeto de lógica digital, máquinas de estado e implementação de protocolos de comunicação em Verilog para FPGA.

O projeto foi totalmente desenvolvido na Lattice Diamond IDE, a ferramenta oficial para dispositivos Lattice. Para a gravação da bitstream no FPGA, foi utilizada a ferramenta de código aberto openFPGALoader.
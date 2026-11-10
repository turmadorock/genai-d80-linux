# genai-d80-linux

Driver Linux (CUPS) para a impressora térmica portátil **GENAI Térmica D80**, uma impressora A4 de rolo de 216 mm, parecido com papel de fax, com cabo USB-C e Bluetooth.

O mesmo aparelho é vendido como **Luck Jingle D80** e **ByteCintia D80**. O fabricante é a Xiamen Lujiang Technology (FCC ID `2A74A-D80`) e só oferece drivers para Windows e macOS.

*English: CUPS driver for the GENAI / Luck Jingle / ByteCintia D80 A4 portable thermal printer (USB-C and Bluetooth). Run `sudo bash instalar.sh`.*

## O que funciona

- Impressão de qualquer programa, de documentos e PDFs em A4, Carta, Ofício, A5, B5 ou rolo contínuo.
- Impressão pelo **cabo USB-C** (fila `D80`) e pelo **Bluetooth** (fila `D80-BT`).
- Ajuste horizontal de -20 a +20 mm.
- Corte do papel em branco no fim da página.
- Atalhos no menu do sistema, **Conectar D80 Cabo** e **Conectar D80 Bluetooth**, para trocar a impressora padrão.

Testado no Linux Mint 22.3 (base Ubuntu 24.04) com CUPS 2.4.

## Instalação

Deixe a impressora ligada (luz verde) e, se quiser, conectada pelo cabo.

```bash
git clone https://github.com/<seu-usuario>/genai-d80-linux.git
cd genai-d80-linux
sudo bash instalar.sh
```

O instalador:
1. Copia o filtro `rastertod80` para `/usr/lib/cups/filter/` e o `genai-d80.ppd` para `/usr/share/cups/model/genai/`.
2. Cria a fila `D80` (USB-C) e a deixa como impressora padrão.
3. Procura a impressora no Bluetooth, com nome `DP_D80_XXXX`, e cria a porta `/dev/rfcomm0` (serviço `rfcomm-d80`). Também libera essa porta para o CUPS no AppArmor, com uma linha em `/etc/apparmor.d/local/usr.sbin.cupsd`, e cria a fila `D80-BT`.
4. Instala os atalhos **Conectar D80 Cabo** e **Conectar D80 Bluetooth**.
5. Imprime a página `testes/teste-V2-A.pdf`, que tem uma moldura na borda do A4.

Para remover tudo: `sudo bash desinstalar.sh`.

## Ajuste horizontal

Se a moldura da página de teste sair deslocada, ajuste em milímetros. Valores negativos movem a impressão para a esquerda.

```bash
lpadmin -p D80 -o Horizontal=-1
lpadmin -p D80-BT -o Horizontal=-1
```

O padrão é **-1 mm**, o valor que deixou a unidade testada perfeita.

## Como funciona

- A cabeça imprime 1728 pontos (216 mm a 203 dpi) e aceita imagem no formato ESC/POS `GS v 0`.
- As medidas de página seguem o `D80.ppd` do driver oficial de macOS (v1.0.6). Ele usa A4 de 595×841 pt, margem zero e deslocamento horizontal de ±20 mm.
- O filtro `rastertod80`, em Python 3 sem dependências, lê o raster do CUPS e centraliza a página na cabeça. Depois aplica o ajuste horizontal, remove as linhas em branco do fim e envia blocos `GS v 0` na largura total.
- As opções `Horizontal` e `SavePaper` são lidas do trabalho (`lp -o`) ou do padrão da fila (`lpadmin -o`).

## Arquivos

| Arquivo | Para que serve |
|---|---|
| `rastertod80` | Filtro CUPS (raster → ESC/POS) |
| `genai-d80.ppd` | Descrição da impressora para o CUPS |
| `instalar.sh` / `desinstalar.sh` | Instalação e remoção |
| `conectar-d80-cabo.sh` / `conectar-d80-bluetooth.sh` | Trocar a impressora padrão entre cabo e Bluetooth |
| `testes/` | Páginas de teste com régua e moldura |

## Licença

MIT. Veja [LICENSE](LICENSE). Este projeto não é afiliado à GENAI, Luck Jingle, ByteCintia nem Xiamen Lujiang.

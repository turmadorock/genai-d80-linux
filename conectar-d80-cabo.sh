#!/usr/bin/env bash
# Conectar D80 Cabo — deixa a GENAI D80 (USB-C) como impressora padrão.
# Uso: bash conectar-d80-cabo.sh   (ou pelo menu: "Conectar D80 Cabo")

avisar() { echo "$1"; command -v notify-send >/dev/null && notify-send -i printer "GENAI D80" "$1"; }

if ! lsusb -d 0fe6:811e >/dev/null 2>&1; then
  avisar "Cabo não detectado. Ligue a D80 e conecte o cabo USB-C, depois rode de novo."
  exit 1
fi

if ! lpstat -p D80 >/dev/null 2>&1; then
  avisar "A fila D80 não existe. Rode primeiro: sudo bash instalar.sh"
  exit 1
fi

cupsenable D80 2>/dev/null
cupsaccept D80 2>/dev/null
lpadmin -d D80 2>/dev/null
avisar "D80 conectada pelo CABO e definida como impressora padrão."
lpstat -d

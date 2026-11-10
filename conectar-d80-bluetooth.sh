#!/usr/bin/env bash
# Conectar D80 Bluetooth — deixa a GENAI D80 sem fio (D80-BT) como impressora padrão.
# Uso: bash conectar-d80-bluetooth.sh   (ou pelo menu: "Conectar D80 Bluetooth")

MAC=''
[ -r /etc/genai-d80.conf ] && . /etc/genai-d80.conf && MAC=${D80_MAC:-}
[ -n "$MAC" ] || MAC=$(bluetoothctl devices | awk '/DP_D80_[0-9A-F]{4}$/ {print $2; exit}')

avisar() { echo "$1"; command -v notify-send >/dev/null && notify-send -i printer "GENAI D80" "$1"; }

if [ -z "$MAC" ]; then
  avisar "Endereço Bluetooth da D80 desconhecido. Ligue a impressora e rode: sudo bash instalar.sh"
  exit 1
fi

if ! lpstat -p D80-BT >/dev/null 2>&1; then
  avisar "A fila D80-BT não existe. Rode primeiro: sudo bash instalar.sh"
  exit 1
fi

# 1) Bluetooth do computador ligado
if ! bluetoothctl show | grep -q "Powered: yes"; then
  bluetoothctl power on >/dev/null 2>&1
  sleep 2
fi
if ! bluetoothctl show | grep -q "Powered: yes"; then
  avisar "Não consegui ligar o Bluetooth do computador. Ligue-o nas configurações e rode de novo."
  exit 1
fi

# 2) Impressora ligada e ao alcance AGORA (procura por até 10 s; não confia no cache)
if ! timeout 12 bluetoothctl --timeout 10 scan on 2>/dev/null | grep -q "$MAC"; then
  avisar "D80 não respondeu no Bluetooth. Ligue a impressora (luz verde), deixe perto do computador e tente de novo."
  exit 1
fi
bluetoothctl trust "$MAC" >/dev/null 2>&1

# 3) Porta serial /dev/rfcomm0 ligada à impressora (pede senha só se precisar)
if ! rfcomm -a 2>/dev/null | grep -q "rfcomm0: $MAC"; then
  pkexec systemctl restart rfcomm-d80.service || {
    avisar "Não consegui criar a porta /dev/rfcomm0."; exit 1; }
fi

# 4) O CUPS precisa de permissão do AppArmor para abrir a porta Bluetooth
if ! grep -qs '/dev/rfcomm' /etc/apparmor.d/local/usr.sbin.cupsd; then
  avisar "Falta liberar o Bluetooth para o CUPS. Rode de novo: sudo bash instalar.sh"
  exit 1
fi

# 5) Fila sem fio como padrão
cupsenable D80-BT 2>/dev/null
cupsaccept D80-BT 2>/dev/null
lpadmin -d D80-BT 2>/dev/null
avisar "D80 encontrada no Bluetooth e definida como impressora padrão."
lpstat -d

#!/usr/bin/env bash
# Remove o driver da GENAI D80 instalado por instalar.sh
# Uso:  sudo bash desinstalar.sh
set -u
[ "$(id -u)" = 0 ] || { echo "Rode com: sudo bash $0"; exit 1; }
lpadmin -x D80 2>/dev/null
lpadmin -x D80-BT 2>/dev/null
systemctl disable --now rfcomm-d80.service 2>/dev/null
rm -f /etc/systemd/system/rfcomm-d80.service /etc/genai-d80.conf
systemctl daemon-reload
LOCAL=/etc/apparmor.d/local/usr.sbin.cupsd
# a regra do AppArmor é comum às impressoras Bluetooth: só sai se a outra não usa Bluetooth
if [ -e "$LOCAL" ] && [ ! -e /etc/systemd/system/rfcomm-ka1445.service ]; then
  sed -i '/dev\/rfcomm/d' "$LOCAL"
  apparmor_parser -r /etc/apparmor.d/usr.sbin.cupsd
fi
rm -f /usr/lib/cups/filter/rastertod80 /usr/share/cups/model/genai/genai-d80.ppd
rmdir /usr/share/cups/model/genai 2>/dev/null
rm -f /usr/local/bin/conectar-d80-cabo /usr/local/bin/conectar-d80-bluetooth \
      /usr/share/applications/conectar-d80-cabo.desktop /usr/share/applications/conectar-d80-bluetooth.desktop
rm -rf /usr/share/genai-d80
# o painel é comum às duas impressoras: só sai se a outra também não estiver instalada
if [ ! -e /usr/lib/cups/filter/rastertoka1445 ]; then
  rm -f /usr/local/bin/painel-impressoras /usr/share/applications/painel-impressoras.desktop
fi
echo "Driver da GENAI D80 removido."

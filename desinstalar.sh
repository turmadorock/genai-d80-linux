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
if [ -e "$LOCAL" ] && grep -q 'GENAI D80' "$LOCAL"; then
  sed -i '/GENAI D80/d' "$LOCAL"
  apparmor_parser -r /etc/apparmor.d/usr.sbin.cupsd
fi
rm -f /usr/lib/cups/filter/rastertod80 /usr/share/cups/model/genai/genai-d80.ppd
rmdir /usr/share/cups/model/genai 2>/dev/null
rm -f /usr/local/bin/conectar-d80-cabo /usr/local/bin/conectar-d80-bluetooth \
      /usr/share/applications/conectar-d80-cabo.desktop /usr/share/applications/conectar-d80-bluetooth.desktop
echo "Driver da GENAI D80 removido."

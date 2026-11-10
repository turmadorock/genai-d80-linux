#!/usr/bin/env bash
# Instalador do driver Linux da GENAI Térmica D80 (Luck Jingle / Xiamen Lujiang, A4 216 mm, 203 dpi)
#   - filtro CUPS rastertod80 + PPD genai-d80.ppd
#   - fila "D80"    pelo cabo USB-C
#   - fila "D80-BT" pelo Bluetooth (porta serial /dev/rfcomm0)
#   - atalhos no menu: "Conectar D80 Cabo" e "Conectar D80 Bluetooth"
# Uso (na pasta do projeto):  sudo bash instalar.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Rode com: sudo bash $0"; exit 1; }
DIR=$(cd "$(dirname "$0")" && pwd)
CONF=/etc/genai-d80.conf
PPD=/usr/share/cups/model/genai/genai-d80.ppd
USUARIO=${SUDO_USER:-}

echo "== 1/5 Filtro e PPD =="
command -v python3 >/dev/null || apt-get install -y python3
install -m 755 -o root -g root "$DIR/rastertod80" /usr/lib/cups/filter/rastertod80
install -D -m 644 "$DIR/genai-d80.ppd" "$PPD"

echo "== 2/5 Fila pelo cabo (D80) =="
USB_URI=$(lpinfo --include-schemes usb -v 2>/dev/null | awk '/D80/ {print $2; exit}')
USB_URI=${USB_URI:-'usb:///D80?serial=000000000000000000000000'}
echo "URI: $USB_URI"
lpadmin -x D80 2>/dev/null || true
lpadmin -p D80 -E -v "$USB_URI" -P "$PPD" -D "GENAI Térmica D80 (cabo)" -o printer-is-shared=false 2>/dev/null
lpadmin -d D80

echo "== 3/5 Bluetooth =="
MAC=${D80_MAC:-}
if [ -z "$MAC" ]; then
  echo "Procurando a D80 no Bluetooth (deixe ligada, luz verde)..."
  bluetoothctl power on >/dev/null 2>&1 || true
  MAC=$(timeout 15 bluetoothctl --timeout 12 scan on 2>/dev/null \
        | grep -oE '([0-9A-F]{2}:){5}[0-9A-F]{2} DP_D80_[0-9A-F]{4}$' | awk '{print $1; exit}' || true)
  [ -n "$MAC" ] || MAC=$(bluetoothctl devices | awk '/DP_D80_[0-9A-F]{4}$/ {print $2; exit}')
fi
if [ -n "$MAC" ]; then
  echo "D80 Bluetooth: $MAC"
  echo "D80_MAC=$MAC" > "$CONF"
  bluetoothctl trust "$MAC" >/dev/null 2>&1 || true
  cat >/etc/systemd/system/rfcomm-d80.service <<EOF
[Unit]
Description=Porta serial Bluetooth da GENAI D80
After=bluetooth.service
Requires=bluetooth.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/rfcomm bind 0 $MAC 1
ExecStop=/usr/bin/rfcomm release 0
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable rfcomm-d80.service >/dev/null
  systemctl restart rfcomm-d80.service
  # O AppArmor do cupsd bloqueia /dev/rfcomm* por padrão
  LOCAL=/etc/apparmor.d/local/usr.sbin.cupsd
  if [ -e /etc/apparmor.d/usr.sbin.cupsd ]; then
    touch "$LOCAL"
    grep -q '/dev/rfcomm\* rw,' "$LOCAL" || echo '/dev/rfcomm* rw,   # GENAI D80 Bluetooth' >> "$LOCAL"
    apparmor_parser -r /etc/apparmor.d/usr.sbin.cupsd
  fi
  lpadmin -x D80-BT 2>/dev/null || true
  lpadmin -p D80-BT -E -v "serial:/dev/rfcomm0?baud=115200" -P "$PPD" \
          -D "GENAI Térmica D80 (Bluetooth)" -o printer-is-shared=false 2>/dev/null
else
  echo "D80 não encontrada no Bluetooth: pulei esta parte."
  echo "Para instalar depois: ligue a impressora e rode de novo (ou D80_MAC=XX:XX:... sudo -E bash instalar.sh)."
fi

echo "== 4/5 Atalhos no menu =="
install -D -m 644 "$DIR/testes/teste-V2-A.pdf" /usr/share/genai-d80/teste.pdf
install -m 755 "$DIR/painel-impressoras.py" /usr/local/bin/painel-impressoras
cat > /usr/share/applications/painel-impressoras.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Impressoras Térmicas
Comment=Painel da GENAI D80 e da Kapbom KA-1445: conexão, orientação, qualidade e testes
Exec=/usr/local/bin/painel-impressoras
Icon=printer
Terminal=false
Categories=Utility;Settings;HardwareSettings;
EOF
install -m 755 "$DIR/conectar-d80-cabo.sh" /usr/local/bin/conectar-d80-cabo
install -m 755 "$DIR/conectar-d80-bluetooth.sh" /usr/local/bin/conectar-d80-bluetooth
for k in cabo:Cabo bluetooth:Bluetooth; do
  cat > /usr/share/applications/conectar-d80-${k%%:*}.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Conectar D80 ${k#*:}
Comment=Define a GENAI D80 (${k%%:*}) como impressora padrão
Exec=/usr/local/bin/conectar-d80-${k%%:*}
Icon=printer
Terminal=false
Categories=Utility;Settings;
EOF
done

echo "== 5/5 Página de teste =="
if lsusb -d 0fe6:811e >/dev/null 2>&1; then
  lp -d D80 -t "TESTE V2-A" "$DIR/testes/teste-V2-A.pdf"
else
  echo "(cabo desconectado: página de teste não enviada; use o painel 'Impressoras Térmicas')"
fi
echo
lpstat -v
echo
echo "Pronto. Se a impressão sair deslocada, ajuste em mm (-20 a +20):"
echo "  lpadmin -p D80 -o Horizontal=-1      (e o mesmo para D80-BT)"

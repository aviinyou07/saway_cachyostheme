#!/usr/bin/env bash
# ==============================================================================
# CYBER STUDIO WAYBAR // DYNAMIC VPN STATUS DETECTOR
# ==============================================================================

country_name() {
    case "${1^^}" in
        AD) echo "Andorra" ;; AE) echo "UAE" ;; AL) echo "Albania" ;;
        AM) echo "Armenia" ;; AR) echo "Argentina" ;; AT) echo "Austria" ;;
        AU) echo "Australia" ;; AZ) echo "Azerbaijan" ;; BA) echo "Bosnia" ;;
        BE) echo "Belgium" ;; BG) echo "Bulgaria" ;; BR) echo "Brazil" ;;
        CA) echo "Canada" ;; CH) echo "Switzerland" ;; CL) echo "Chile" ;;
        CN) echo "China" ;; CO) echo "Colombia" ;; CY) echo "Cyprus" ;;
        CZ) echo "Czech Rep." ;; DE) echo "Germany" ;; DK) echo "Denmark" ;;
        EE) echo "Estonia" ;; EG) echo "Egypt" ;; ES) echo "Spain" ;;
        FI) echo "Finland" ;; FR) echo "France" ;; GB) echo "UK" ;;
        GR) echo "Greece" ;; HK) echo "Hong Kong" ;; HR) echo "Croatia" ;;
        HU) echo "Hungary" ;; ID) echo "Indonesia" ;; IE) echo "Ireland" ;;
        IL) echo "Israel" ;; IN) echo "India" ;; IS) echo "Iceland" ;;
        IT) echo "Italy" ;; JP) echo "Japan" ;; KR) echo "S. Korea" ;;
        LT) echo "Lithuania" ;; LU) echo "Luxembourg" ;; LV) echo "Latvia" ;;
        MD) echo "Moldova" ;; MX) echo "Mexico" ;; MY) echo "Malaysia" ;;
        NL) echo "Netherlands" ;; NO) echo "Norway" ;; NZ) echo "New Zealand" ;;
        PH) echo "Philippines" ;; PK) echo "Pakistan" ;; PL) echo "Poland" ;;
        PT) echo "Portugal" ;; QA) echo "Qatar" ;; RO) echo "Romania" ;;
        RS) echo "Serbia" ;; RU) echo "Russia" ;; SA) echo "Saudi Arabia" ;;
        SE) echo "Sweden" ;; SG) echo "Singapore" ;; SK) echo "Slovakia" ;;
        TH) echo "Thailand" ;; TR) echo "Turkey" ;; TW) echo "Taiwan" ;;
        UA) echo "Ukraine" ;; US) echo "USA" ;; VN) echo "Vietnam" ;;
        ZA) echo "South Africa" ;; *) echo "${1^^}" ;;
    esac
}

# ------------------------------------------------------------------------------
# Fast path first: is there a tunnel interface at all?
# ------------------------------------------------------------------------------
# This module polls every 5s. It used to open with `nmcli`, which is a D-Bus
# round-trip to NetworkManager and measured 62ms -- about 18 minutes of CPU per
# day, nearly all of it spent confirming the usual answer of "no VPN".
#
# Globbing /sys/class/net is a directory read in the shell with no process spawn
# at all, so the common case now costs effectively nothing, and nmcli is only
# consulted once a tunnel is actually up and its pretty name is needed.
TUN_IFACE=""
for _if in /sys/class/net/*; do
    _n="${_if##*/}"
    case "$_n" in
        wg[0-9]*|tun[0-9]*|tap[0-9]*|proton[0-9]*|nordlynx*|mullvad*|tailscale*|warp*)
            TUN_IFACE="$_n"; break ;;
    esac
done

# No tunnel device -> no VPN. Emit empty to fully collapse the pill.
if [[ -z "${TUN_IFACE}" ]]; then
    echo '{"text": "", "tooltip": "No VPN active. Status: Direct Gateway.", "class": "disconnected"}'
    exit 0
fi

# A tunnel exists, so the expensive lookup is now justified: ask NetworkManager
# for the connection's real name (e.g. "ProtonVPN CH-JP#2") to parse a country
# from. If NM does not know about it -- a wg-quick or tailscaled tunnel it did
# not create -- fall back to the interface name.
RAW_NAME=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
    | awk -F: '($2 ~ /wireguard|vpn|tun|tap|openvpn|ipsec|ppp|tailscale/) && $0 !~ /killswitch|leak/ {print $1; exit}')
[[ -n "${RAW_NAME}" ]] || RAW_NAME="${TUN_IFACE}"

# Parse country code from ProtonVPN/Mullvad style names (e.g. "ProtonVPN CH-JP#2" → JP → Japan)
CODE=$(echo "${RAW_NAME}" | grep -oP '\b[A-Z]{2}\b' | tail -1)
COUNTRY=""
[[ -n "${CODE}" ]] && COUNTRY=$(country_name "${CODE}")

# Get protocol
PROTO=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null \
    | awk -F: -v n="${RAW_NAME}" '$1 == n {print $2; exit}')
case "${PROTO}" in
    wireguard) PROTO_LABEL="WireGuard" ;;
    vpn)       PROTO_LABEL="OpenVPN" ;;
    tailscale) PROTO_LABEL="Tailscale" ;;
    *)         PROTO_LABEL="${PROTO:-Encrypted}" ;;
esac

# Build display text
if [[ -n "${COUNTRY}" ]]; then
    DISPLAY="$(echo "${COUNTRY}" | tr '[:upper:]' '[:lower:]')"
else
    DISPLAY=$(echo "${RAW_NAME}" | sed 's/ProtonVPN\s*//i; s/Mullvad\s*//i; s/NordVPN\s*//i' \
        | tr '[:upper:]' '[:lower:]' | xargs)
fi

# Emit valid single-line JSON (no literal newlines — use \n escape sequence)
TOOLTIP="Protected by VPN\\nServer: ${RAW_NAME}\\nCountry: ${COUNTRY:-Unknown}\\nProtocol: ${PROTO_LABEL}\\nStatus: Encrypted & Secure"

SHIELD="󰒃"

printf '{"text": "%s %s", "tooltip": "%s", "class": "connected"}\n' \
    "${SHIELD}" "${DISPLAY}" "${TOOLTIP}"

exit 0

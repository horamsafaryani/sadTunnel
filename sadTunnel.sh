# sadTunnel Is Here / By t.me/NotHoRaM

# -------------------- Colors -------------------- #
white="\e[1m\e[0m"
gray="\e[1m\e[30m"
red="\e[1m\e[31m"
green="\e[1m\e[32m"
yellow="\e[1m\e[33m"
blue="\e[1m\e[34m"
# ------------------- Variables ------------------ #
VERSION="V1.0.0"
OS_NAME=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
echo "Fetching server IP and location..."
IPV4=$(curl -s https://ipv4.icanhazip.com)
IPV6=$(curl -s https://ipv6.icanhazip.com)
LOCATION_INFO=$(curl -s "https://ipwhois.app/json/${IPV4}")
COUNTRY=$(echo "$LOCATION_INFO" | jq -r '.country')
CITY=$(echo "$LOCATION_INFO" | jq -r '.city')
LOCATION="$COUNTRY - $CITY"
# ------------------ Functions ------------------- #
function loading {
    spin[0]="-"
    spin[1]="/"
    spin[2]="\\"
    spin[3]="-"
    PID=$!
    echo -n "${spin[0]}"
    while [ -d /proc/$PID ]
    do
        for i in "${spin[@]}"
        do
            echo -ne "\b$i"
            sleep 0.1
        done
    done
    wait $PID
    if [ $? -ne 0 ]; then
        echo -e "\n$red Error!"
    else
        echo -e "\b$red Done."
    fi
}

function updates {
    apt update && apt upgrade -y
    if [ "$?" != "0" ]; then
        exit 1
    fi
}

function requirementsF {
    apt install netplan.io -y
    if [ "$?" != "0" ]; then
        exit 1
    fi
}

function requirementsI {
    apt install netplan.io wget nano gzip zip unzip -y
    wget https://github.com/ginuerzh/gost/releases/download/v2.11.5/gost-linux-amd64-2.11.5.gz
    gunzip gost-linux-amd64-2.11.5.gz
    mv gost-linux-amd64-2.11.5 /usr/local/bin/gost
    chmod +x /usr/local/bin/gost
    if [ "$?" != "0" ]; then
        exit 1
    fi
}

function installF() {
    echo -e $yellow
    read -e -p "    Do You Want To Install Required Packages ? (Y or N) " input
    if [ "$input" = "y" -o "$input" = "Y" ]; then
        echo -en "$green\n        Updating Server Packages..\n"
        updates >> /dev/null 2>&1 & loading
        sleep 1
        echo -en "$green\n        Installing Required Packages..\n"
        requirementsF >> /dev/null 2>&1 & loading
    fi
    echo -e $white
}

function installI() {
    echo -e $yellow
    read -e -p "    Do You Want To Install Required Packages ? (Y or N) " input
    if [ "$input" = "y" -o "$input" = "Y" ]; then
        echo -en "$green\n        Updating Server Packages..\n"
        updates >> /dev/null 2>&1 & loading
        sleep 1
        echo -en "$green\n        Installing Required Packages..\n"
        requirementsI >> /dev/null 2>&1 & loading
    fi
    echo -e $white
}

function netPlanSettingsF {
    local Loc=$1
    local IpIR=$2
    local IpFO=$3
    local TunIPv6=$4
    cat > /etc/netplan/$Loc.yaml <<EOF
network:
  version: 2
  tunnels:
    tunel-$Loc:
      mode: sit
      local: $IpFO
      remote: $IpIR
      addresses:
        - $TunIPv6::1/64
EOF
}

function netPlanSettingsI {
    local Loc=$1
    local IpIR=$2
    local IpFO=$3
    local TunIPv6=$4
    cat > /etc/netplan/$Loc.yaml <<EOF
network:
  version: 2
  tunnels:
    tunel-$Loc:
      mode: sit
      local: $IpIR
      remote: $IpFO
      addresses:
        - $TunIPv6::10/64
EOF
}

function gostSettingsI {
    local LocalIPv6="$1"
    local TunPort="$2"
    local gostFile="/usr/lib/systemd/system/gost.service"

    local gostConfig="[Unit]
Description=GO Simple Tunnel
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gost \\
-L=tcp://:${TunPort}/[${LocalIPv6}::1]:${TunPort}

[Install]
WantedBy=multi-user.target"

    if [ ! -f "$gostFile" ]; then
        echo -e "$gostConfig" > "$gostFile"
    else
        sed -i "/^ExecStart=/d" "$gostFile"
        sed -i "/^Type=simple/a ExecStart=/usr/local/bin/gost \\\\\n-L=tcp://:${TunPort}/[${LocalIPv6}::1]:${TunPort} \\\\" "$gostFile"
    fi
}

function generate_random_ipv6 {
    echo "fd$(printf '%02x' $((RANDOM % 0xff))):$(printf '%x' $((RANDOM % 0x10000))):$(printf '%x' $((RANDOM % 0x10000))):$(printf '%x' $((RANDOM % 0x10000)))"
}

function setupNetplanF {
    clear
    echo -e $gray
    read -e -p "$(echo -e " Enter Local IPv6 Name ( Default : $COUNTRY ) : ${green}")" TunName
    TunName=${TunName:-$COUNTRY}
    echo -e $green
    echo "  Local IPv6 Name : $TunName"
    sleep 0.4
    clear
    echo -e $gray
    read -e -p "$(echo -e " Enter IranVPS IPv4 : ${green}")" IpIR
    echo -e $green
    echo "  IR IPv4 : $IpIR"
    sleep 0.4
    clear
    echo -e $red
    echo "      Local-IPv6 Should Be The Same as What You Set on The IRAN Server !"
    echo "               Or You Should Enter RandomIPv6 In IR Server"
    echo -e $gray
    read -e -p "$(echo -e " Enter Your Local IPv6 ( Enter For Random ) : ${green}")" TunIPv6
    echo -e $red
    echo "      It Should Be The Same as What You Set on The IRAN Server !"
    echo "             Or You Should Enter RandomIPv6 In IR Server"
    if [ -z "$TunIPv6" ]; then
        TunIPv6=$(generate_random_ipv6)
    fi
    echo -e $green
    echo "  Local IPv6 : $TunIPv6"
    sleep 0.4
    clear
    echo -e $yellow
    echo -e "   Local IPv6 Info :"
    echo ""
    echo -e "$gray  Local IPv6 Name : $green $TunName"
    echo -e "$gray  IR IPv4 : $green $IpIR"
    echo -e "$gray  FO IPv4 : $green $IPV4"
    echo -e "$gray  Local IPv6 : $green $TunIPv6"
    echo -e $red
    echo "      Make Sure You Have Saved Local IPv6 IPv6 !"
    echo "         You Should Enter It In IRAN Server"
    echo -e "${green}           Saved at : /root/sadTunnel.log"
    echo -e $yellow
    read -e -p "$(echo -e " Is Details Ok? (Y or N) : ${green}")" input
    if [ "$input" = "y" -o "$input" = "Y" ]; then
        netPlanSettingsF "$TunName" "$IpIR" "$IPV4" "$TunIPv6"
        netplan apply > /dev/null 2>&1
        clear
        echo "Configuration Done."
    else
    clear
    echo -e $gray
        echo "Returning To Main Menu."
    sleep 1
    fi
    echo -e $white
}
function setupNetplanI {
    clear
    echo -e $gray
    read -e -p "$(echo -e " Enter Local IPv6 Name ( That You Entered In Foreign Server ) : ${green}")" TunName
    TunName=${TunName:-$COUNTRY}
    echo -e $green
    echo "  Local IPv6 Name : $TunName"
    sleep 0.4
    clear
    echo -e $gray
    read -e -p "$(echo -e " Enter ForeignVPS IPv4 : ${green}")" IpFO
    echo -e $green
    echo "  FO IPv4 : $IpFO"
    sleep 0.4
    clear
    echo -e $red
    echo "      Local-IPv6 Should Be The Same as What You Set on The IRAN Server !"
    echo "               Or You Should Enter RandomIPv6 In IR Server"
    echo -e $gray
    read -e -p "$(echo -e " Enter Your Local IPv6 ( Enter For Random ) : ${green}")" TunIPv6
    echo
    if [ -z "$TunIPv6" ]; then
        TunIPv6=$(generate_random_ipv6)
    fi
    echo -e $green
    echo "  Local IPv6 : $TunIPv6"
    sleep 0.4
    clear
    echo -e $yellow
    echo -e "   Local IPv6 Info :"
    echo ""
    echo -e "$gray  Local IPv6 Name : $green $TunName"
    echo -e "$gray  IR IPv4 : $green $IPV4"
    echo -e "$gray  FO IPv4 : $green $IpFO"
    echo -e "$gray  Local IPv6 : $green $TunIPv6"
    echo -e $red
    echo "       Make Sure You Have Saved This Details !"
    echo "        You Should Enter It In Foreign Server"
    echo -e "${green}           Saved at : /root/sadTunnel.log"
    echo -e $yellow
    read -e -p "$(echo -e " Is Details Ok? (Y or N) : ${green}")" input
    if [ "$input" = "y" -o "$input" = "Y" ]; then
        netPlanSettingsI "$TunName" "$IPV4" "$IpFO" "$TunIPv6"
        netplan apply > /dev/null 2>&1
        clear
        echo "Configuration Done."
    else
    clear
    echo -e $gray
        echo "Returning To Main Menu."
    sleep 1
    fi
    echo -e $white
}

function setupGostI {
    clear
    echo -e $gray
    read -e -p "$(echo -e " Enter Local IPv6 ( That You Entered In Section 2 ) : ${green}")" TunIPv6
    echo -e $green
    echo "  Tunnel Local IPv6 : $TunIPv6"
    sleep 0.4
    clear
    echo -e $gray
    read -e -p "$(echo -e " Enter That Port You Want To Tunnel : ${green}")" TunPort
    echo -e $green
    echo "  Tunnel Port : $TunPort"
    sleep 0.4
    clear
    echo -e $yellow
    echo -e "   Tunnel Info :"
    echo ""
    echo -e "$green $TunIPv6 : $TunPort"
    echo -e $yellow
    read -e -p "$(echo -e " Is Details Ok? (Y or N) : ${green}")" input
    if [ "$input" = "y" -o "$input" = "Y" ]; then
        gostSettingsI "$TunIPv6" "$TunPort"
        systemctl daemon-reload > /dev/null 2>&1
        service gost restart > /dev/null 2>&1
        clear
        echo "Configuration Done."
    else
    clear
    echo -e $gray
        echo "Returning To Main Menu."
    sleep 1
    fi
    echo -e $white
}
# ---------------- Start Scripts ----------------- #
if ! command -v figlet &> /dev/null
then
    apt install -y figlet > /dev/null 2>&1
fi

clear
if [[ "$COUNTRY" == "Iran" ]]; then
    while true; do
    echo -e $white
    figlet -f big "     sadTunnel"
    echo "      Server Operating System : $OS_NAME"
    echo "      Server IPv4 : $IPV4"
    echo "      Server IPv6 : $IPV6"
    echo "      Server Location : $LOCATION"
    echo ""
    echo "      Script Version : $VERSION"
    echo ""
    echo "   Is IR Server? : ✅"
    echo ""
        echo "      1. Install Requirements"
        echo "      2. Setup Local IPv6"
        echo "      3. Setup Tunnel"
        echo "      0. Exit"
        echo ""
        read -e -p "Choose an Option : " option

        case $option in
            1) 
                installI
                ;;
            2) 
                setupNetplanI
                ;;
            3) 
                setupGostI
                ;;
            0) 
                echo "Exiting..."
                exit 0
                ;;
            *)
                clear
                echo "Invalid , Try Again :D"
                sleep 1
                ;;
        esac
    done
else
    while true; do
    echo -e $white
    figlet -f big "     sadTunnel"
    echo "      Server Operating System : $OS_NAME"
    echo "      Server IPv4 : $IPV4"
    echo "      Server IPv6 : $IPV6"
    echo "      Server Location : $LOCATION"
    echo ""
    echo "      Script Version : $VERSION"
    echo ""
    echo "   Is IR Server? : ❌"
    echo ""
        echo "      1. Install Requirements"
        echo "      2. Setup Local IPv6"
        echo "      0. Exit"
        echo ""
        read -e -p "Choose an Option : " option

        case $option in
            1)
                installF
                ;;
            2)
                setupNetplanF
                ;;
            0)
                echo "Exiting..."
                exit 0
                ;;
            *)
                clear
                echo "Invalid , Try Again :D"
                sleep 1
                ;;
        esac
    done
fi

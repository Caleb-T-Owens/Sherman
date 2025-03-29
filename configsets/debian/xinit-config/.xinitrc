while [ true ]; do
    BAT_VALUE=$(cat /sys/class/power_supply/BAT0/capacity)
    DATE=$(date "+%H:%M %d/%m/%Y")
    xsetroot -name "$DATE $BAT_VALUE%"
    sleep 60
done &
exec /usr/local/bin/dwm

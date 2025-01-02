# DNS-O-Matic automatic DNS updates

# User account info of DNS-O-Matic
:local maticuser "your_username"
:local maticpass "your_password"

# Host name to update
:local matichost "your_host" # Use "all.dnsomatic.com" to update all
# WAN Interface to get IP for update
:local inetinterface "interface_name"
# The reference host to compare old IP bedore updating
:local maticnoiphost "your_noip_host" 

# Get the current IP registered on the Host Name from No-IP
:global previousIP [:resolve $maticnoiphost];

# Get the current IP on the WAN interface
:global currentIP [/ip address get [find interface="$inetinterface" disabled=no] address]

# Check if the interface is up
:if ([/interface get $inetinterface value-name=running]) do={

# Strip the net mask off the IP address
   :for i from=( [:len $currentIP] - 1) to=0 do={
       :if ( [:pick $currentIP $i] = "/") do={ 
           :set currentIP [:pick $currentIP 0 $i]
       } 
   }
}

# Check if the IP from the WAN interface has changed comparing with the IP from No-IP
:if ($currentIP != $previousIP) do={
    :log info "DNS-O-Matic: Update needed"
    :set previousIP $currentIP
    :log info "DNS-O-Matic: Sending update for $matichost with IP $currentIP"
    /tool fetch url="https://updates.dnsomatic.com/nic/update\3Fhostname=$matichost&myip=$currentIP&wildcard=NOCHG&mx=NOCHG&backmx=NOCHG" user=$maticuser password=$maticpass mode=https dst-path=update_result.txt
    :log info "DNS-O-Matic: Update successful"
} else={
    # If the IP has not changed, do nothing
    :log info "DNS-O-Matic: No update needed, IP unchanged"
}

# You can reduce the logging for "No update needed" commenting the "else" lines.
# Remember to add a schedule for automatic updates, recommended to start on RouterOS "startup" and repeat every 3 to 5 minutes.

# End of script
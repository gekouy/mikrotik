# No-IP automatic DNS updates
# Currently working on RouterOS 7.16.2
# ---------------------------------------------------------------------------------------
# Change the variables below to match your configuration:
# ---------------------------------------------------------------------------------------

# User account info of No-IP
:local noipuser "your_username"
:local noippass "your_password"

# No-IP hostname to update
:local noiphost "your.domain.com"

# WAN Interface to get IP for update
:local inetinterface "interface_name"  # Could be ether1, pppoe-out1, etc.

# ---------------------------------------------------------------------------------------
# Don't change anything else below this line unless you know what you are doing:
# ---------------------------------------------------------------------------------------

# Get the current IP registered on the Host Name from No-IP
:global previousIP [:resolve $noiphost];

# Check if the interface is up
:if ([/interface get $inetinterface value-name=running]) do={

# Get the current IP on the interface
   :local currentIP [/ip address get [find interface="$inetinterface" disabled=no] address]

# Strip the net mask off the IP address
   :for i from=( [:len $currentIP] - 1) to=0 do={
       :if ( [:pick $currentIP $i] = "/") do={ 
           :set currentIP [:pick $currentIP 0 $i]
       } 
   }

# Check if the IP from the WAN interface has changed comparing with the IP from No-IP
   :if ($currentIP != $previousIP) do={
       :log info "No-IP: La actual IP $currentIP no es igual a la anterior, necesita actualizar!"
	   # If changed, update the IP on the previousIP variable
       :set previousIP $currentIP

	   # Send the update to DNS-O-Matic using the variables: ? is a special character in commands so the hex "\3F" is needed for question mark.
       :local url "http://dynupdate.no-ip.com/nic/update\3Fmyip=$currentIP"
       :local noiphostarray
       :set noiphostarray [:toarray $noiphost]
       :foreach host in=$noiphostarray do={
           :log info "No-IP: Sending update for host $host"
           /tool fetch url=($url . "&hostname=$host") user=$noipuser password=$noippass mode=http dst-path=("no-ip_ddns_update-" . $host . ".txt")
           :log info "No-IP: The host $host was updated to the following IP $currentIP"
       }
   }  else={
       :log info "No-IP: No update needed, IP unchanged"
   }
} else={
   :log info "No-IP: No-IP: No update needed, IP unchanged"
}

# ---------------------------------------------------------------------------------------
#     You can reduce the logging for "No update needed" commenting the "else" lines.
#   Remember to add a schedule for automatic updates, recommended to start on RouterOS
#                      "startup" and repeat every 3 to 5 minutes.
# ---------------------------------------------------------------------------------------
#                                    End of script
# ---------------------------------------------------------------------------------------

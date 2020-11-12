# This is the default configuration settings.
# DO NOT CHANGE THE VALUES IN THIS FILE
# use rootCustomConfig.sh instead

# substring offset <optional length> string
# cuts a string at the starting offset and wanted length.
substring() {
        local init=$1; shift
        if [ "$2" != "" ]; then toFetch="\(.\{$1\}\).*"; shift; else local toFetch="\(.*\)"; fi
        echo "$1" | $bb sed -e "s/^.\{$init\}$toFetch$/\1/"
}

# the name of the jail, leaving this at the default is recommended.
jailName=@JAILNAME@

# If set to true, this will create a new network namespace for the jail
# enabling the jail to have it's own "private" network access.
# When false, the jail gets exactly the same network access as the
# base system.
jailNet=true

# If set to true, a new bridge will be created with the name
# bridgeName(see below). This permits external sources to join
# it (jails or otherwise) and potentially gaining access to
# services from this jail.
# NOTE : Creating a bridge requires privileged access.
createBridge=false
# this is the bridge we will create if createBridge=true
bridgeName=$(substring 0 13 $jailName)
# only used if createBridge=true
bridgeIp=192.168.99.1
bridgeIpBitmask=24

# This creates a pair of virtual ethernet devices which can be
# used to access the ressources from this jail from the base system
# and, with the help of firewall rules, access from abroad too.
# It does not grant access to the internet by itself.
# See setNetAccess for that.
# NOTE : This is only available when jailNet=true.
# NOTE : Enabling networking requires privileged access.
networking=false

# this is the external IP.
# Only valid if networking=true
extIp=172.16.0.1
extIpBitmask=24

# This is automatically set but you can change this value
# if you like. You may for example decide to make a jail
# only pass through a tunnel or a vpn. Otherwise, keep
# this value to the default value.
#netInterface=<network interface>
netInterface=@DEFAULTNETINTERFACE@

# This boolean sets if you want your jail to
# gain full internet access using a technique called
# SNAT or Masquerading. This will make the jail able to
# access the internet and your LAN as if it was on the
# host system.
# Only valid if networking=true
setNetAccess=false

# chroot internal IP
# the one liner script is to make sure it is of the same network
# class as the extIp.
# Just change the ending number to set the IP.
# defaults to "2"
ipInt=$(echo $extIp | $bb sed -e 's/^\(.*\)\.[0-9]*$/\1\./')2
# chroot internal IP mask
ipIntBitmask=24
# These are setup only if networking is true
# the external veth interface name (only 15 characters maximum)
vethExt=$(substring 0 13 $jailName)ex
# the internal veth interface name (only 15 characters maximum)
vethInt=$(substring 0 13 $jailName)in


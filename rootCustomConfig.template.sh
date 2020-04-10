# this is imported from newJail.sh
cat > $newChrootHolder/rootCustomConfig.sh << EOF
#! $sh

# this is the file in which you can put your custom jail's configuration in shell script form

if [ "\$_JAILTOOLS_RUNNING" = "" ]; then
	echo "Don\'t run this script directly, run startRoot.sh instead"
	exit 1
fi

# substring offset <optional length> string
# cuts a string at the starting offset and wanted length.
substring() {
        local init=\$1; shift
        if [ "\$2" != "" ]; then toFetch="\(.\{\$1\}\).*"; shift; else local toFetch="\(.*\)"; fi
        echo "\$1" | sed -e "s/^.\{\$init\}\$toFetch$/\1/"
}

################# Configuration ###############

jailName=$jailName

# the namespace name for this jail
netnsId=\$(substring 0 13 \$jailName)

# if you set to false, the chroot will have exactly the same
# network access as the base system.
jailNet=true

# If set to true, we will create a new bridge with the name
# bridgeName(see below) in our ns creatensId. This permits
# external sources to join it and potentially gaining access
# to services on this jail.
createBridge=false
# this is the bridge we will create if createBridge=true
bridgeName=\$(substring 0 13 \$jailName)
# only used if createBridge=true
bridgeIp=192.168.99.1
bridgeIpBitmask=24

# If you put true here the script will create a veth pair on the base
# namespace and in the jail and do it's best to allow the internet through
# these. The default routing will pass through this device to potentially
# give internet access through it, depending on your choice of firewall below.
# When it's false, you can still manually connect to the net if you like or
# join a bridge to gain fine grained access to ressources.
# Only valid if jailNet=true
configNet=false

# this is the external IP we use only if configNet=true
extIp=192.168.12.1
extIpBitmask=24

# firewall select
# we support : shorewall, iptables
# Any other value will disable basic automatic firewall
# masquerade (forwarding) configuration.
# Note that both the iptables and shorewall implementations
# only allow outbound connections (and their response). It
# does not allow any inbound connections by themselves. For
# that you have to push in your own rules.
# Ideally, you should push these rules from the
# rootCustomConfig script because rules are deleted after the
# jail is closed, by default.
# only used if configNet=true
firewallType=

# shorewall specific options Section, only used if configNet=true
firewallPath=/etc/shorewall
firewallNetZone=net
firewallZoneName=\$(substring 0 5 \$jailName)

# all firewalls options section
# the network interface by which we will masquerade our
# connection (only used if configNet=true)
# leave it empty if you don't want to masquerade your connection
# through any interface.
#snatEth=eth0
snatEth=

# chroot internal IP
# the one liner script is to make sure it is of the same network
# class as the extIp.
# Just change the ending number to set the IP.
# defaults to "2"
ipInt=\$(echo \$extIp | sed -e 's/^\(.*\)\.[0-9]*$/\1\./')2
# chroot internal IP mask
ipIntBitmask=24
# These are setup only if configNet is true
# the external veth interface name (only 15 characters maximum)
vethExt=\$(substring 0 13 \$jailName)ex
# the internal veth interface name (only 15 characters maximum)
vethInt=\$(substring 0 13 \$jailName)in


################# Mount Points ################

# it's important to note that these mount points will *only* mount a directory
# exactly at the same location as the base system but inside the jail.
# so if you put /etc/ssl in the read-only mount points, the place it will be mounted
# is /etc/ssl in the jail. If you want more flexibility, you will have to mount
# manually like the Xauthority example in the function prepCustom.

# dev mount points : read-write, no-exec
devMountPoints_CUSTOM=\$(cat << EOF
@EOF
)

# read-only mount points with exec
roMountPoints_CUSTOM=\$(cat << EOF
/usr/share/locale
/usr/lib/locale
/usr/lib/gconv
@EOF
)

# read-write mount points with exec
rwMountPoints_CUSTOM=\$(cat << EOF
@EOF
)


################ Functions ###################

# this is called before the shell command and of course the start command
# put your firewall rules here
prepCustom() {
	local rootDir=\$1

	# Note : We use the path /home/yourUser as a place holder for your home directory.
	# It is necessary to use a full path rather than the \$HOME env. variable because
	# don't forget that this is being run as root.

	# To add devices (in the /dev folder) of the jail use the addDevices function. You
	# don't need to add the starting /dev path.
	# If for example you wanted to add the 'null' 'urandom' and 'zero' devices you would do :
	# addDevices \$rootDir null urandom zero
	#
	# Note that the jail's /dev directory is now a tmpfs so it's content is purged every time
	# the jail is stopped. Also note that addDevices puts exactly the same file permissions
	# as those on the base system.

	# we check if the file first exists. If not, we create it.
	# you can do the same thing with directories by doing "[ ! -d ..." and "&& mkdir ..."
	# [ ! -e \$rootDir/root/home/.Xauthority ] && touch .Xauthority
	#
	# mounting Xauthority manually (crucial for supporting X11)
	# mount --bind /home/yourUser/.Xauthority \$rootDir/root/home/.Xauthority

	# joinBridgeByJail <jail path> <set as default route> <our last IP bit>
	# To join an already running jail called tor at the path, we don't set it
	# as our default internet route and we assign the interface the last IP bit of 3
	# so for example if tor's bridge's IP is 192.168.11.1 we are automatically assigned
	# the IP : 192.168.11.3
	# joinBridgeByJail /home/yourUser/jails/tor "false" "3"

	# To join a bridge not from a jail.
	# The 1st argument is for if we want to route our internet through that bridge.
	# the 2nd and 3rd arguments : intInt and extInt are the interface names for the
	# internal interface and the external interface respecfully.
	# We left the 4th argument empty because this bridge is on the base system. If it
	# was in it's own namespace, we would use the namespace name there.
	# The 5th argument is the bridge's device name
	# The 6th argument is the last IP bit. For example if tor's bridge's IP is 192.168.11.1
	# we are automatically assigned the IP : 192.168.11.3
	# joinBridge "false" "intInt" "extInt" "" "br0" "3"

	# firewall shorewall examples :
	# Note : There is no need to remove these from stopCustom as they are automatically removed.
	# Note : won't work unless configNet=true and firewallType=shorewall

	# incoming

	# We allow the base system to connect to our jail (all ports) :
	# echo "fw \$firewallZoneName ACCEPT" >> \$firewallPath/policy.d/\$jailName.policy

	# We allow the base system to connect to our jail specifically only to the port 8000 :
	# echo "ACCEPT	fw	\$firewallZoneName tcp 8000" >> \$firewallPath/rules.d/\$jailName.rules

	# We allow the net to connect to our jail specifically to the port 8000 from the port 80 (by dnat) :
	# internet -> port 80 -> firewall's dnat -> jail's port 8000
	# echo "DNAT \$firewallNetZone \$firewallZoneName:\$ipInt:8000 tcp 80" >> \$firewallPath/rules.d/\$jailName.rules

	# outgoing

	# We allow the jail all access to the net zone (all ports) :
	# echo "\$firewallZoneName \$firewallNetZone ACCEPT" >> \$firewallPath/policy.d/\$jailName.policy

	# We allow the jail all access to the base system (all ports) :
	# echo "\$firewallZoneName fw ACCEPT" >> \$firewallPath/policy.d/\$jailName.policy

	# We allow the jail only access to the base system's port 25 :
	# echo "ACCEPT \$firewallZoneName fw tcp 25" >> \$firewallPath/rules.d/\$jailName.rules

}

startCustom() {
	local rootDir=\$1

	# if you want both the "shell" command and this "start" command to have the same parameters,
	# place your instructions in prepCustom and only place "start" specific instructions here.

	# put your chroot starting scripts/instructions here
	# here's an example, by default this is the same as the shell command.
	# just supply your commands to it's arguments.
	# If you want to use your own command with environment variables, do it like so :
	# runJail \$rootDir FOO=bar sh someScript.sh
	# you can't do it like so :
	# runJail \$rootDir env - FOO=bar sh someScript.sh
	# this would nullify important environment variables we set in runJail/runChroot
	# You can override the defaults too, just set them using the above method.
	runJail \$rootDir

	# if you need to add logs, just pipe them to the directory : \$rootDir/run/someLog.log
}

stopCustom() {
	local rootDir=\$1
	# put your stop instructions here

	# this is to be used in combination with the mount --bind example in prepCustom
	# mountpoint \$rootDir/root/home/.Xauthority >/dev/null && umount \$rootDir/root/home/.Xauthority

	# this is to be used in combination with the joinBridgeByJail line in prepCustom
	# leaveBridgeByJail /home/yourUser/jails/tor

	# this is to be used in combination with the joinBridge line in prepCustom
	# leaveBridge "extInt" "" "br0"
}

cmdParse() {
	local args=\$1
	local ownPath=\$2

	case \$args in
		daemon)
			echo "This command is not meant to be called directly, use the jailtools super script to start the daemon properly, otherwise it will just stay running with no interactivity possible."
			prepareChroot \$ownPath || exit 1
			runJail -d \$ownPath
			stopChroot \$ownPath
		;;

		start)
			prepareChroot \$ownPath || exit 1
			startCustom \$ownPath
			stopChroot \$ownPath
		;;

		stop)
			stopChroot \$ownPath
		;;

		shell)
			prepareChroot \$ownPath >/dev/null 2>/dev/null
			if [ "\$?" != "0" ]; then
				echo "Entering the already started jail \\\`\$jailName'"
				nsPid=\$(findNS \$ownPath)
				[ "\$nsPid" != "" ] || echo "Unable to get the running namespace, bailing out" && $nsenterPath $nsenterSupport -t \$nsPid \$(runChroot \$ownPath)
			else # we start a new jail
				runJail \$ownPath
				stopChroot \$ownPath
			fi
		;;

		restart)
			stopChroot \$ownPath
			prepareChroot \$ownPath || exit 1
			startCustom \$ownPath
		;;

		*)
			echo "\$0 : start|stop|restart|shell"
		;;
	esac
}

EOF

# this is imported from newJail.sh
filesystem=$(cat << EOF
/bin
/boot
/dev
/dev/pts
/etc
/etc/pam.d
/lib
/lib/tls
/lib/security
/home
/mnt
/opt
/proc
/sbin
/sys
/root
/tmp
/run
/usr
/usr/bin
/usr/sbin
/usr/lib
/usr/lib/tls
/usr/libexec
/usr/local
/usr/local/bin
/usr/local/lib
/usr/local/lib/tls
/usr/local/sbin
/var
/var/account
/var/cache
/var/empty
/var/games
/var/lib
/var/lock
/var/log
/var/mail
/var/opt
/var/pid
/var/run
/var/spool
/var/state
/var/tmp
/var/yp
EOF
)

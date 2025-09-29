set -o nounset 

group=wheel
user="${1:-${SUDO_USER:-${USER:-}}}"
# In case of elevated privileges, the old user is stored
#   - for sudo, in $SUDO_USER
#   - for run0, in $SUDO_USER
#   - for su, in $USER

if [[ -z "$user" ]]; then
	echo "Error: No a username (or root) provided as first argument" >&2
	exit 1
fi

# If you don't care about passwords the old one was likely bad anyway.
# Remove it so the system can be relatively secure (in case sshd is running or something)
sudo passwd -qd $user
sudo usermod $user -aG $group

sudo rm -f /etc/polkit-1/rules.d/*-passwordless.rules /etc/sudoers.d/*-passwordless /etc/sddm.conf.d/passwordless.conf

function write {
    sudo tee "$@" > /dev/null
}

write /etc/polkit-1/rules.d/49-$group-passwordless.rules << EOF
polkit.addRule(function(action, subject) {
	if (subject.isInGroup("$group")) {
		return polkit.Result.YES;
	}
});
EOF

# Unneccesary when user has no password
write /etc/sudoers.d/99-$group-passwordless << EOF
%$group ALL=(ALL:ALL) NOPASSWD: ALL
EOF

if [[ -n ${DESKTOP_SESSION:-} && -d /etc/sddm.conf.d/ && ! $(grep /etc/sddm.conf* -re "^\[Autologin\]") ]]
then
	sddm_config=/etc/sddm.conf.d/kde_settings.conf
	if [[ -n "$sddm_config" ]]
	then
		sddm_config=/etc/sddm.conf.d/passwordless.conf
	fi
	write -a "$sddm_config" << EOF
[Autologin]
Relogin=false
Session=$DESKTOP_SESSION
User=$user
EOF
fi

if [[ "${XDG_CURRENT_DESKTOP:-}" == "KDE" ]]
then
	write /home/$user/.config/kscreenlockerrc << EOF
[Daemon]
Autolock=false
LockOnResume=false
Timeout=0
EOF
	sudo chown $user /home/$user/.config/kscreenlockerrc
fi

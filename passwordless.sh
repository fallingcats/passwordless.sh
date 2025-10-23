set -o nounset -o errexit

function find-user {
	user="${1:-${SUDO_USER:-${USER:-}}}"
	# In case of elevated privileges, the old user is stored
	#   - for sudo, in $SUDO_USER
	#   - for run0, in $SUDO_USER
	#   - for su, in $USER
	echo $user
}

function find-group {
	group=""
	# use wheel/sudo if user is in either group (prefer wheel)
	if groups "$user" | grep -qw wheel
	then
		group="wheel"
	elif groups "$user" | grep -qw sudo
	then
		group="sudo"

	# use wheel/sudo if either group exists (prefer wheel)
	elif grep -q ^wheel: /etc/group
	then
	group="wheel"
	elif grep -q ^sudo: /etc/group
	then
		group="sudo"

	# groups don't exist
	else
		group="wheel"
		sudo groupadd $group
	fi

	echo $group
}

function setup {
	if [[ -z "$user" ]]; then
		echo "Error: No a username (or root) provided as first argument" >&2
		exit 1
	fi

	# If you don't care about passwords the old one was likely bad anyway.
	# Remove it so the system can be relatively secure (in case sshd is running or something)
	sudo passwd -qd $user
	sudo usermod $user -aG $group

	sudo rm -f /etc/polkit-1/rules.d/*-passwordless.rules /etc/sudoers.d/*-passwordless /etc/sddm.conf.d/passwordless.conf
}

function write {
	sudo tee "$@" > /dev/null
}


function configure-polkit {
	write /etc/polkit-1/rules.d/49-$group-passwordless.rules << EOF
polkit.addRule(function(action, subject) {
	if (subject.isInGroup("$group")) {
		return polkit.Result.YES;
	}
});
EOF
}

function configure-sudo {
	if [[ -f /etc/sudoers.d/010_pi-nopasswd ]]
	then
		if whiptail --title "Remove 010_pi-nopasswd?" --yesno "The file /etc/sudoers.d/010_pi-nopasswd will most likely be made obsolete. Remove it?" 0 0
		then
			sudo rm /etc/sudoers.d/010_pi-nopasswd
		fi
	fi
	write /etc/sudoers.d/99-$group-passwordless << EOF
%$group ALL=(ALL:ALL) NOPASSWD: ALL
EOF
}

function configure-kde-sddm {
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
}

function configure-kde-kscreenlocker {
	# kscreenlocker for Plasma Desktop
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
}



user=$(find-user)
group=$(find-group)
setup
configure-polkit
configure-sudo
configure-kde-sddm
configure-kde-kscreenlocker

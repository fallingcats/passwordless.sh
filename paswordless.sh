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
passwd -d $user
usermod $user -aG $group

rm /etc/polkit-1/rules.d/*-passwordless.rules /etc/sudoers.d/*-passwordless

cat > /etc/polkit-1/rules.d/49-$group-passwordless.rules << EOF
polkit.addRule(function(action, subject) {
	if (subject.isInGroup("$group")) {
		return polkit.Result.YES;
	}
});
EOF

# Unneccesary when user has no password
cat > /etc/sudoers.d/99-$group-passwordless << EOF
%$group ALL=(ALL:ALL) NOPASSWD: ALL
EOF

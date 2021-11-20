#!/bin/bash
FOLDER=$(pwd)
BOOTSTRAP_FILE="${FOLDER}/bootstrap.tbz"
which unzip > /dev/null || {
	echo "Installing unzip"
	sudo apt install unzip -qqy > /dev/null
}
[ -e "$BOOTSTRAP_FILE" ] || {
	echo "Trying to download current packages"
	which wget || sudo apt-get install -qqy wget
	wget -q -O "main.zip" "https://github.com/vt520/kiosk-helpers/archive/refs/heads/main.zip" || {
		cat <<- EOF
			Somethings really broken, you're missing some important files.

			Could not download archive; exiting
		EOF
	}
	unzip -o main.zip > /dev/null && rm main.zip
	[ -e kiosk-helpers-main/bootstrap.sh ] || {
		cat <<- EOF
			So, extraction failed, or the get failed, but this is bad,
			try again.
		EOF
	}
	cd kiosk-helpers-main
	source bootstrap.sh
	exit
}

source setup/promote

read -sp "Bootstrap Password > " -e PASSWORD
echo

function decrypt_file () {
	openssl enc -d \
	-md sha512 \
	-pbkdf2 \
	-iter 100000 \
	-aes256 \
	-pass stdin \
	-in "$1" <<<"$PASSWORD" 2> /dev/null
}

decrypt_file "$BOOTSTRAP_FILE" | tar tj &> /dev/null  || {
	echo "Incorrect password"
	exit
}

echo $(echo -n "$PASSWORD" | sha256sum | sed -r 's/ .*//')
declare -x SETUP_HASHWORD=$(echo -n "$PASSWORD" | sha256sum | sed -r 's/ .*//')
declare -x GIT_SSH_COMMAND='ssh -i /etc/kiosk/protected/identity -o IdentitiesOnly=yes'

mkdir -p /etc/kiosk/protected/
chmod o+rwx,ug-rwx /etc/kiosk/protected
cd /etc/kiosk/protected

decrypt_file "$BOOTSTRAP_FILE" | tar xj > /dev/null  && {
	mv -f "sdios_bootstrap" "identity"
	mv -f "sdios_bootstrap.pub" "identity.pub"
	chmod u+rw,ugo-x,og-rw *
}

echo "$FOLDER/.git/"
[ -e "${FOLDER}/.git/" ] || {
	echo "Creating repository information"
	cd "$FOLDER"
	git clone --bare git@github.com:vt520/kiosk-helpers.git .git > /dev/null
	git init > /dev/null
}

[ "$FOLDER" != "/setup/kiosk-helpers" ] && {
	echo "Relocating folder to /setup"
	mkdir -p /setup
	rm -rf /setup/kiosk-helpers
	mv "$FOLDER" /setup/kiosk-helpers
	FOLDER="/setup/kiosk-helpers"
}
cd "$FOLDER"

[ -e /setup/kiosk-helpers ] && cd /setup/kiosk-helpers

echo "Updating to current"
USER_ID="$(id -nu):$(id -ng)"

chown -R $USER_ID /setup/kiosk-helpers
chmod  u+rwx $(find /setup/kiosk-helpers/* -type d)

git reset --hard > /dev/null
git pull | grep " is now at "
cd ~

sudo -- chown -R root:root /setup/kiosk-helpers
cd "$FOLDER"
mv bootstrap.sh reinstall
chmod +x reinstall

cat <<- EOF

	Bootstrapping finished; starting installer in 5 seconds
	hit CTRL+C to abort.

	To Re-Run this script, execute /setup/kiosk-helpers/reinstall

EOF
sleep 5 || echo "use 'cd .' to reload your directory"

chmod  a+x setup/install
setup/install

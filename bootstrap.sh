#!/bin/bash

# Downloads the repository as a zip; and installs the SSH keys

function decrypt_file () {
	openssl enc -d \
	-md sha512 \
	-pbkdf2 \
	-iter 100000 \
	-aes256 \
	-pass stdin \
	-in "$1" <<<"$PASSWORD" 2> /dev/null
}

SOURCE_PROVIDER="vt520/kiosk-helpers"
SOURCE_CHANNEL="main"

FOLDER=$(pwd)
BOOTSTRAP_FILE="${FOLDER}/bootstrap.tbz"

BASH_ARGV0=$(pwd)/$(basename $0)

which unzip > /dev/null || {
	echo "Installing wget"
	sudo apt install wget -qqy &> /dev/null || exit 1
}
which unzip > /dev/null || {
	echo "Installing unzip"
	sudo apt install unzip -qqy &> /dev/null || exit 1
}

wget -q -O "${SOURCE_CHANNEL}.zip" "https://github.com/${SOURCE_PROVIDER}/archive/refs/heads/main.zip" || {
	cat <<- EOF
		Somethings really broken, you're missing some important files.
		Could not download archive; exiting
	EOF
}

unzip "${SOURCE_CHANNEL}.zip" > /dev/null && rm "${SOURCE_CHANNEL}.zip" > /dev/null
SOURCE_DIRECTORY=$(basename ${SOURCE_PROVIDER})"-${SOURCE_CHANNEL}"

cd "${SOURCE_DIRECTORY}"

source setup/promote

[ -e "${BOOTSTRAP_FILE}" ] && {
	echo
	echo "Encrypted bootstrap shim found"
	read -sp "Bootstrap Password > " -e PASSWORD
	echo
	# Test Decryption
	decrypt_file "$BOOTSTRAP_FILE" | tar tj &> /dev/null  || {
		echo "Incorrect password"
		exit
	}

	mkdir -p /etc/kiosk/protected/
	chmod o+rwx,ug-rwx /etc/kiosk/protected

	decrypt_file "$BOOTSTRAP_FILE" | tar xj > /dev/null  && {
		mv -f "sdios_bootstrap" "identity"
		mv -f "sdios_bootstrap.pub" "identity.pub"
		chmod u+rw,ugo-x,og-rw *
	}

	declare -x SETUP_HASHWORD=$(echo -n "$PASSWORD" | sha256sum | sed -r 's/ .*//')
	echo "Your setup hashword is: ${SETUP_HASHWORD}"
}

declare -x FOLDER=$(pwd)

[ "${FOLDER}" != "/setup/kiosk-helpers" ] && {
	echo "Relocating folder to /setup"
	mkdir -p /setup
	rm -rf /setup/kiosk-helpers
	cd ..
	mv "${SOURCE_DIRECTORY}" /setup/kiosk-helpers
	FOLDER="/setup/kiosk-helpers"
}

cd /setup/kiosk-helpers
sudo -- chown -R root:root /setup/kiosk-helpers

mv "$0" reinstall
chmod +x reinstall

cat <<- EOF

	Bootstrapping finished; starting installer in 5 seconds
	hit CTRL+C to abort.

	To Re-Run this script, execute /setup/kiosk-helpers/reinstall

EOF
sleep 5 || echo "use 'cd .' to reload your directory"

chmod  a+x setup/install
setup/install
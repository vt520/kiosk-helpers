#!/bin/bash
FOLDER=$(pwd)
BOOTSTRAP_FILE="${FOLDER}/bootstrap.tbz"
which unzip > /dev/null || {
	echo "Installing unzip"
	sudo apt install unzip -qqy
}
[ -e "$BOOTSTRAP_FILE" ] || {
	echo "Trying to download current packages"
	which wget || sudo apt-get install -qqy wget
	wget -q -O "main.zip" "https://github.com/vt520/kiosk-helpers/archive/refs/heads/main.zip" || {
		cat <<- EOF
			Somethings really broken, you're missing bootstrap.tbz
			Please contact your support provider
			Could not install wget; exiting
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

declare -x SETUP_HASHWORD=$(sha256sum <<<$PASSWORD | sed -r 's/ .*//')

cat <<- EOF
This is going to change your SSH User keys and the location of this repo.
The keys are pre-registered with the remote server for immediate access.
The repository will be moved to /setup and have proper permissions applied

type "BAIL" without quotes to exit; anything else to continue
EOF
read -p "Proceed? > " -e PROCEED
[ "$PROCEED" != "BAIL" ] || exit

cd ~
[ -e .ssh ] || mkdir .ssh
chmod u+rwx,go-rwx .ssh
cd .ssh
decrypt_file "$BOOTSTRAP_FILE" | tar xj > /dev/null  && {
	mv -f "sdios_bootstrap" "id_rsa"
	mv -f "sdios_bootstrap.pub" "id_rsa.pub"
	chmod u+rw,ugo-x,og-rw *
}

echo "$FOLDER/.git/"
[ -e "${FOLDER}/.git/" ] || {
	echo "Creating repository information"
	cd "$FOLDER"
	git clone --bare git@github.com:vt520/kiosk-helpers.git .git
	git init
}

# this part needs to run as sudo
[ "$FOLDER" != "/setup/kiosk-helpers" ] && {
	echo "Relocating folder to /setup"
	sudo mkdir -p /setup
	sudo rm -rf /setup/kiosk-helpers
	sudo mv "$FOLDER" /setup/kiosk-helpers
	FOLDER="/setup/kiosk-helpers"
	cd "$FOLDER"
}

[ -e /setup/kiosk-helpers ] && cd /setup/kiosk-helpers

echo "Updating to current"
USER_ID="$(id -nu):$(id -ng)"

sudo -- chown -R $USER_ID /setup/kiosk-helpers
sudo -- chmod  u+rwx $(find /setup/kiosk-helpers/* -type d)

git reset --hard
git pull
cd ~

sudo -- chown -R root:root /setup/kiosk-helpers
cat <<- EOF
	Bootstrapping finished; starting installer in 30 seconds
	hit CTRL+C to abort
	$FOLDER
EOF
sleep 30 || echo "use 'cd .' to reload your directory"
cd "$FOLDER"

sudo -- chmod  a+x setup/install
setup/install

# vim: set ft=make :


# List recipes
list:
	just --list



# Update system
update-system:
	sudo rpm-ostree update
   

# Update system
update-flatpaks:
	sudo flatpak update -y


# Update Distrobox containers
update-containers:
	distrobox upgrade -a


# Update device firmware
[no-exit-message]
update-firmware:
	sudo fwupdmgr --force refresh
	sudo fwupdmgr get-updates
	sudo fwupdmgr update


# Update Nix
update-nix:
	#!/usr/bin/env bash
	set -ueo pipefail
	if [[ -d "/nix" ]]
	then
		sudo -i nix upgrade-nix
		sudo rm -f /etc/systemd/system/nix-daemon.service
		sudo rm -f /etc/systemd/system/nix-daemon.socket
		sudo cp /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.service /etc/systemd/system/nix-daemon.service
		sudo cp /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.socket /etc/systemd/system/nix-daemon.socket
		sudo systemctl daemon-reload
		sudo systemctl enable --now nix-daemon
	else
		echo "Nix not installed"
	fi

# Update Nix's Home-Manager environment
update-home-manager:
	#!/usr/bin/env bash
	set -ueo pipefail
	if [[ -f "${HOME}/.config/vlm/home_manager_installed" ]]
	then
		nix flake update --flake ~/.config/home-manager/
		home-manager switch --flake ~/.config/home-manager/
	else
		echo "Home Manager not installed"
	fi


# Clean up system
clean-system:
	#!/usr/bin/env bash
	set -ueo pipefail
	podman system prune -a
	sudo flatpak uninstall --unused
	sudo rpm-ostree cleanup -bm
	if [ -x "$(command -v nix-store)" ]
	then
		sudo nix-store --gc
		sudo nix-store --optimise
	fi


# Update Devbox
update-devbox:
	#!/usr/bin/env bash
	set -ueo pipefail
	if [[ -f "/etc/vlm/devbox_installed" ]]
	then
		sudo curl -fsSL https://get.jetpack.io/devbox | bash -s -- -f
	else
		echo "Devbox not installed"
	fi


# Update DevPod
update-devpod:
	#!/usr/bin/env bash
	set -ueo pipefail
	if [[ -f "/etc/vlm/devpod_installed" ]]
	then
		sudo sh /etc/vlm/uninstall/uninstall_devpod.sh
		rm -fr /tmp/devpod
		mkdir -p /tmp/devpod
		wget -P /tmp/devpod https://github.com/loft-sh/devpod/releases/latest/download/DevPod_linux_x86_64.tar.gz
		tar xf /tmp/devpod/DevPod_linux_x86_64.tar.gz -C /tmp/devpod
		sudo cp -r /tmp/devpod/usr/* /usr/local/
		sudo mkdir -p /etc/vlm/uninstall
		find /tmp/devpod/usr -type f | sudo tee /etc/vlm/uninstall/uninstall_devpod.sh > /dev/null
		sudo sed -i 's/\/tmp\/devpod\/usr/sudo rm \/usr\/local\//g' /etc/vlm/uninstall/uninstall_devpod.sh
		rm -fr /tmp/devpod
	else
		echo "DevPod not installed"
	fi


# Update everything
update-all: update-system update-flatpaks update-containers update-nix update-home-manager update-devbox update-devpod

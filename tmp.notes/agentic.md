For Question 9, you stated: The bloat-removal list. Based on what Bazzite's images actually ship (verified against bazzite.gg and docs): Steam (patched RPM), umu-launcher, gamescope + gamescope-session, MangoHud, gamemode, Waydroid (Android container, configured by default), Decky Loader, PowerStation, HHD (handheld daemon), InputPlumber, OpenRazer/Oversteer (peripherals), BlueBubbles (iMessage), Firefox (patched RPM), Bazzite Portal (first-boot app installer), distrobox/podman tooling, zsh+fastfetch/starship setup, jupiter-theme & Steam Deck integrations, plus assorted Flatpaks. Which of these should halcyon strip out (GNOME is already going per R8)?

Response:
You need to keep steam pactched rpm, umu-launcher, gamescope + gamescope-session, usb-based peripherals and controller stuff, Bazzite Portal + bazaar, distrobox/podman setup (also add distroshelf, like rpm package),

You need to Remove Waydroid, Decky Loader and other handheld stuff, BlueBubbles, Firefox patch rpm; remove everything jupiter related stuff and steam deck integrations.

You also need to remove zsh+fastfetch/starship setup because I will add my own setup later on with the bazzite setup integrated on top of my setup.

Keep a lean gamer preset.

Try to replace Flatpak packages with optimized rpm packages from non-fedora repos if possible like ublue-os copr repos

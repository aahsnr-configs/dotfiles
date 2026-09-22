sudo findmnt -no UUID -T /swap/swapfile ⌂ 08:15

sudo password for ahsan:
57fc6474-7cc5-4ffb-8997-5c1580a4652c

sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
27043072

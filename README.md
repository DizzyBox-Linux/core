# Core

Updates/edits to https://github.com/MichielDerhaeg/build-linux for small USB

## Depends (Slackware)
* fakeroot
* musl
* Qemu kinda i guess

## Depends (Ubuntu)
* musl-tools
* fakeroot
* build-essential
* flex (not in `build-essential` i guess?)

## Notes
* enabled init msg in bb config
* `make oldconfig` - update kernel config for newer version
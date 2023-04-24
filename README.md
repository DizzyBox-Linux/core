# Core

Updates/edits to https://github.com/MichielDerhaeg/build-linux

## Depends (Slackware)
* fakeroot
* musl
* Qemu kinda i guess

## Depends (Ubuntu)
* musl-tools
* fakeroot
* build-essential
* flex (not in `build-essential` i guess?)
* libelf-dev
* nasm

## Notes
* enabled init msg in bb config
* `make oldconfig` - update kernel config for newer version
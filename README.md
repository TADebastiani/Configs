# TADebastiani Configs

My default configurations. Changing those configurations to use _GNU Stow_.

Configs using old style:
- external-disk
- docker
- desktop-entries
- vim

All configs is for `$HOME` directory, as configured on `.stowrc` file.
One exception is _keyboard_ configs.

## Usage

### Old Style
For configs using old style, check `install.sh` help usage:
```sh
cd Configs
./install.sh --help
```

### GNU Stow
For configs using Stow:
```sh
cd Configs
stow {FOLDER}
```
Change `{FOLDER}` to folder name, example: `stow starship`.

For keyboard configs, must be run as root and specify root folder as target:
```sh
cd Configs
sudo stow --target=/ keyboard
```

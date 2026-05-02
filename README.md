## apm - a shitty suckless AUR helper


It's a shitty suckless AUR helper written in POSIX sh because uhh suckless or smth 

> Warning: This kinda sucks. Wouldn't use it if I were you

## concept

Shitty suckless AUR helper written in POSIX sh becaus writing shitty suckless stuff is funny or smth

## Dependencies

- `man`
- `git`
- `base-devel`
- `curl`
- `less`
- `coreutils`
- `base`


## Installation

```sh
make
sudo/doas make install  
```

## Usage


  
```sh
  usage: apm <command> [package]

  commands:
  install,  -S     install a package (with selection if ambiguous)
  search,   -Ss    search and select a package interactively
  update,   -Su    check for updates
  upgrade,  -Syu   upgrade outdated packages
  remove,   -R     remove a package
  info,     -Si    show package information
  deps,     -Sd    show package dependencies
  list,     -Q     list installed aur packages
  clean            clear build cache
  log              show install/remove history
  fetch            system information
  version,  -V     show version
  ```

> For more information ,read the man page provided


## License

GPL-v3

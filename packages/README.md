# Package lists

One package per line; `#` starts a comment. Official repositories only (core, extra), except
`aur.txt`. The installer reads every list it is told to install, checks each name with
`pacman -Si` after syncing, and installs all of them in **one** `pacman -Syu --needed`
transaction (never a partial upgrade).

A name prefixed with `?` is optional: if the repositories do not have it (renamed, dropped, or a
name that could not be verified from the build environment), the installer warns and skips it.
A missing name **without** `?` stops the installer before anything is installed.

CI (`.github/workflows/ci.yml`) runs the same check in an `archlinux:latest` container, so a
renamed package shows up as a failed check instead of a failed install. When CI confirms a `?`
name, drop the `?`.

| File | Installed |
| --- | --- |
| desktop.txt | always: Hyprland stack, shell surfaces, audio, login, fonts, theming |
| shell.txt | always: terminals, zsh, CLI tools |
| apps.txt | always: file managers, browsers, Code - OSS |
| editors.txt | always: Neovim, Helix, vis and what they need to build parsers |
| languages.txt | asked (default yes): Elixir, Haskell, SWI-Prolog, Scala, OCaml, Fortran toolchains |
| office.txt | asked (default yes): TeX Live (full), TeXstudio, texlab, LibreOffice, dictionaries |
| network.txt | only when no network manager is active |
| amd-gpu.txt | when an AMD GPU is detected: Mesa, Vulkan |
| blender.txt | asked (default yes with an AMD GPU): Blender with HIP rendering |
| aur.txt | asked (default no): built with makepkg from the AUR |

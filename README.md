NixOS для LiveUSB флешки, без установки, десктопный компьютер
Предустановленны:
```
KDE Plasma, компиляторы Rust и Lean, Google Chrome и VS Code.
Шифрование подключаемых дисков (fscrypt, ext4)
Набор пакетов git, docker...
```

Собираю на удалённом сервере

```
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=iso.nix
```



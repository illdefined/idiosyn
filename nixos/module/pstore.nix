{ ... }: { lib, config, ... }: {
  environment.etc."systemd/pstore.conf".text = ''
    [PStore]
    Storage=journal
    Unlink=true
  '';
}

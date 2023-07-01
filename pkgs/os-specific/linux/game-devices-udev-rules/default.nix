{
  lib,
  stdenv,
  fetchFromGitea,
}:
stdenv.mkDerivation rec {
  pname = "game-devices-udev-rules";
  version = "0.21";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "fabiscafe";
    repo = "game-devices-udev";
    rev = version;
    hash = "sha256-Yy91yDF5BSDTTlr/Pj8e0UklPooEdzvRW8mkhdHtHVo=";
  };

  installPhase = ''
    runHook preInstall
    install -Dm444 -t "$out/lib/udev/rules.d" *.rules
    runHook postInstall
  '';

  meta = with lib; {
    description = "Udev rules to make supported controllers available with user-grade permissions";
    homepage = "https://codeberg.org/fabiscafe/game-devices-udev";
    license = licenses.mit;
    longDescription = ''
      These udev rules are intended to be used as a package under 'services.udev.packages'.
      They will not be activated if installed as 'environment.systemPackages' or 'users.user.<user>.packages'.

      Additionally, you may need to enable 'hardware.uinput'.
    '';
    platforms = platforms.linux;
    maintainers = with maintainers; [keenanweaver];
  };
}

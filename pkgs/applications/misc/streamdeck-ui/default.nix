{ lib
, python3Packages
, fetchFromGitHub
, fetchPypi
, copyDesktopItems
, writeText
, makeDesktopItem
, wrapGAppsHook3
, xvfb-run
, qt6
}:
let
  # There are breaking changes between 6 and 7
  importlib-metadata_6 = python3Packages.importlib-metadata.overrideAttrs (_: rec {
    version = "6.9.0";
    src = fetchPypi {
      pname = "importlib_metadata";
      inherit version;
      hash = "sha256-6Ky1I8M1qRgiZ04Um0bAOZ7E0yjE0fbknCc9pf8CAbk=";
    };
  });
in
python3Packages.buildPythonApplication rec {
  pname = "streamdeck-ui";
  version = "4.1.2";

  src = fetchFromGitHub {
    repo = "streamdeck-linux-gui";
    owner = "streamdeck-linux-gui";
    rev = "v${version}";
    hash = "sha256-CSsFPGnKVQUCND6YOA9kfO41KS85C57YL9LcrWlQRKo=";
  };

  desktopItems = let
    common = {
      name = "streamdeck-ui";
      desktopName = "Stream Deck UI";
      icon = "streamdeck-ui";
      exec = "streamdeck";
      comment = "UI for the Elgato Stream Deck";
      categories = [ "Utility" ];
    };
  in builtins.map makeDesktopItem [
    common
    (common // {
      name = "${common.name}-noui";
      exec = "${common.exec} --no-ui";
      noDisplay = true;
    })
  ];

  postInstall =
    let
      udevRules = ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", TAG+="uaccess"
      '';
    in
      ''
        mkdir -p $out/lib/systemd/user
        substitute scripts/streamdeck.service $out/lib/systemd/user/streamdeck.service \
          --replace '<path to streamdeck>' $out/bin/streamdeck

        mkdir -p "$out/etc/udev/rules.d"
        cp ${writeText "70-streamdeck.rules" udevRules} $out/etc/udev/rules.d/70-streamdeck.rules

        mkdir -p "$out/share/pixmaps"
        cp streamdeck_ui/logo.png $out/share/pixmaps/streamdeck-ui.png
      '';

  dontWrapQtApps = true;
  dontWrapGApps = true;
  makeWrapperArgs = [ "\${qtWrapperArgs[@]}" "\${gappsWrapperArgs[@]}"];

  format = "pyproject";

  nativeBuildInputs = [
    python3Packages.poetry-core
    python3Packages.pythonRelaxDepsHook
    copyDesktopItems
    qt6.wrapQtAppsHook
    wrapGAppsHook3
  ];

  pythonRelaxDeps = [ "pillow" ];

  propagatedBuildInputs =
    with python3Packages;
    [
      setuptools
      filetype
      cairosvg
      pillow
      pynput
      pyside6
      streamdeck
      xlib
      importlib-metadata_6
      evdev
    ]
    ++ lib.optionals stdenv.isLinux [ qt6.qtwayland ];

  nativeCheckInputs = [
    xvfb-run
  ] ++ (with python3Packages; [
    pytest
    pytest-qt
    pytest-mock
  ]);

  checkPhase = ''
    # The tests needs to find the log file
    export STREAMDECK_UI_LOG_FILE=$(pwd)/.streamdeck_ui.log
    xvfb-run pytest tests
  '';

  meta = with lib; {
    description = "Linux compatible UI for the Elgato Stream Deck";
    homepage = "https://streamdeck-linux-gui.github.io/streamdeck-linux-gui/";
    license = licenses.mit;
    mainProgram = "streamdeck";
    maintainers = with maintainers; [ majiir ];
  };
}

final: prev:
let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  dmgPackage = pname: version: url: sha256: sourceRoot:
    prev.stdenv.mkDerivation rec {
      inherit version pname sourceRoot;

      src = prev.fetchurl {
        name = "${pname}-${version}.dmg";
        inherit url sha256;
      };

      dontPatch = true;
      dontConfigure = true;
      dontBuild = true;
      dontFixup = true;
      phases = [ "unpackPhase" "installPhase" ];
      nativeBuildInputs = [ prev.pkgs.unzip ];

      unpackCmd = ''
        if ! [[ "$curSrc" =~ \.dmg$ ]]; then return 1; fi
            mnt=$(mktemp -d -t ci-XXXXXXXXXX)

        function clean {
            /usr/bin/hdiutil detach $mnt -force
            rm -rf $mnt
        }
        trap clean EXIT

        /usr/bin/hdiutil attach -nobrowse -readonly $src -mountpoint $mnt

        ls -la $mnt/

        shopt -s extglob
        DEST="$PWD"
        (cd "$mnt"; cp -a !(Applications) "$DEST/")
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/Applications/$sourceRoot
        cp -R . "$out/Applications/$sourceRoot"

        runHook postInstall
      '';

      meta = {
        platforms = [ "aarch64-darwin" ];
      };
    };

    arrayToObject = inputArray: builtins.foldl' (acc: elem: acc // { "${elem.pname}" = elem; }) {} inputArray;
    packages = arrayToObject (map (x: dmgPackage x.name x.version x.url x.sha256 x.source_root) sources);
in
packages

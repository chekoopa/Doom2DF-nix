{ lib, stdenv, fetchgit, fetchzip
, makeWrapper, makeDesktopItem, runCommand, copyDesktopItems
, unzip, fpc, SDL2, SDL2_mixer, libX11, enet, libGL, glibc
}:

let
  pname = "doom2df";
  version = "0.667";
  name = "${pname}-${version}";

  meta = {
    description = "Doom-themed platformer with network play";
    longDescription = ''
      Doom 2D: Forever is an open source OpenGL side-scrolling shooter for 
      Windows, Android and Linux, a modern port of the 1996 Doom 2D by 
      Prikol Software. It is based upon Doom, and is essentially the 
      original Doom translated into a two-dimensional arcade or console-like
      shooter, comparable to the original Duke Nukem. The game includes
      single player, cooperative, deathmatch, and CTF multiplayer.
    '';
    homepage = "https://www.doom2d.org/";
    license = lib.licenses.gpl3Plus;
    # maintainers = with lib.maintainers; [ chekoopa ];
    platforms = lib.platforms.linux;
  };   

  desktopItem = makeDesktopItem {
    name = "doom2df";
    exec = "Doom2DF";
    comment = meta.description;
    desktopName = "Doom 2D Forever";
    categories = [ "Game" "Shooter" "ActionGame" ];
    icon = "doom2df";
    startupNotify = false;
    # TODO: fix icons
    # TODO: add next options
    # Version=${version} 
    # Comment=Doom-themed platformer with network play, modern port of the 1996 Doom 2D by Prikol Software
    # Comment[ru]=Платформер с сетевой игрой во вселенной классического Doom, современный порт игры Doom 2D от Prikol Software
    # Keywords=Doom;Doom2D;Doom2D Forever;Forever;Shooter;Doom 2D;
  };

  doom2df-unwrapped = stdenv.mkDerivation rec {
    pname = "doom2df-unwrapped";
    inherit version;

    src = fetchgit {
      url = "https://repo.or.cz/d2df-sdl.git";
      rev = "fbbc2cfe8253d61c8a5eb27d352df4103a59b7fb";
      sha256 = "sha256-hBRqZMHBcEBKPFM60ev8cYvHTBpFvTsWGdlC93wASsk=";
    };

    buildInputs = [ fpc enet SDL2.dev SDL2_mixer ];
  
    buildPhase = ''
      ls
      mkdir bin tmp
      cd src/game
      fpc -O2 -dUSE_SDL2 -dUSE_SDLMIXER -dUSE_OPENGL -FE../../bin -FU../../tmp Doom2DF.lpr
    '';
    
    installPhase = ''
      install -Dm644 ../../rpm/res/doom2df.png \
        $out/share/icons/hicolor/256x256/doom2df.png
      install -Dm755 ../../bin/Doom2DF "$out/bin/Doom2DF"
    '';

    dontPatchELF = true;
    postFixup =''
      patchelf \
          --add-needed ${glibc}/lib/libpthread.so.0 \
          --add-needed ${SDL2.out}/lib/libSDL2-2.0.so.0 \
          --add-needed ${SDL2_mixer.out}/lib/libSDL2_mixer-2.0.so.0 \
          --add-needed ${enet.out}/lib/libenet.so.7 \
          --add-needed ${glibc}/lib/libdl.so.2 \
          --add-needed ${libX11.out}/lib/libX11.so.6 \
          --add-needed ${glibc}/lib/libc.so.6 \
          --add-needed ${libGL.out}/lib/libGL.so.1 \
          $out/bin/Doom2DF
    '';
  };

in rec {
  # TODO: добыть стабильную ссылку на игровые данные (легко может протухнуть)
  doom2df-data = fetchzip {
    name = "doom2df-data";
    url = "https://doom2d.org/doom2d_forever/latest/doom2df-win32.zip";
    sha256 = "sha256-Buj/emC2sFeREOOL05MyJWBwlNNBwlxTD7hBa+0G3sM=";
    stripRoot = false;
    postFetch = ''
      cd $out
      rm -rf *.dll *.exe
    '';
    meta.hydraPlatforms = [];
    passthru.version = version;
  };

  doom2df = runCommand "doom2df-${version}" {
    inherit doom2df-unwrapped;
    nativeBuildInputs = [ makeWrapper copyDesktopItems ];
    desktopItems = [ desktopItem ];
    passthru = {
      inherit version;
      meta = meta // {
        hydraPlatforms = [];
      };
    };
  } (''
    mkdir -p $out/bin
    ln -s ${doom2df-unwrapped}/bin/Doom2DF $out/bin/
    mkdir -p $out/share
    ln -s ${doom2df-unwrapped}/share/icons $out/share/icons
    copyDesktopItems
    wrapProgram $out/bin/Doom2DF --add-flags "--ro-dir ${doom2df-data} --ro-dir \$HOME/.doom2df"
  '');
}

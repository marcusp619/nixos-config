# Custom CS8409 HDA audio driver for Apple MacBook Pro (2016/2017).
# Replaces the mainline snd_hda_codec_cs8409 with an Apple-specific version
# that properly initialises the internal speaker/headphone amplifiers.
# Source: https://github.com/davidjo/snd_hda_macbookpro
{ stdenv, fetchFromGitHub, kernel, lib }:

stdenv.mkDerivation {
  pname   = "snd_hda_macbookpro";
  version = "unstable-2024-11-${kernel.version}";

  src = fetchFromGitHub {
    owner = "davidjo";
    repo  = "snd_hda_macbookpro";
    rev   = "ed1b488be81c25c1eee81671a6a82332437917f2";
    hash  = "sha256-j1UBKhXRBxRpG11UMk1eufe6FKjCDO9W8HR+WVAQLK0=";
  };

  hardeningDisable  = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  unpackPhase = ''
    runHook preUnpack
    cp -r $src/. .
    chmod -R u+w .

    mkdir -p build/hda
    tar --strip-components=3 \
        -xf ${kernel.src} \
        --directory=build/hda \
        "linux-${kernel.version}/sound/hda"
    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild

    hda="$(pwd)/build/hda"

    cp makefiles/Makefile         $hda/Makefile
    cp makefiles/Makefile_common  $hda/common/Makefile
    cp makefiles/Makefile_codecs  $hda/codecs/Makefile
    cp makefiles/Makefile_cirrus  $hda/codecs/cirrus/Makefile

    cp patch_cirrus/cirrus_apple.h                  $hda/codecs/cirrus/
    cp patch_cirrus/patch_cirrus_boot84.h           $hda/codecs/cirrus/
    cp patch_cirrus/patch_cirrus_new84.h            $hda/codecs/cirrus/
    cp patch_cirrus/patch_cirrus_real84.h           $hda/codecs/cirrus/
    cp patch_cirrus/patch_cirrus_hda_generic_copy.h $hda/codecs/cirrus/
    cp patch_cirrus/patch_cirrus_real84_i2c.h       $hda/codecs/cirrus/

    mv $hda/codecs/cirrus/cs8409.c $hda/codecs/cirrus/cs8409.c.orig
    mv $hda/codecs/cirrus/cs8409.h $hda/codecs/cirrus/cs8409.h.orig

    work_dir="$(pwd)"
    pushd $hda
    patch -p1 < $work_dir/patch_cs8409.c.diff
    patch -p1 < $work_dir/patch_cs8409.h.diff
    popd

    mv $hda/codecs/cirrus/cs8409.c.orig $hda/codecs/cirrus/cs8409.c
    mv $hda/codecs/cirrus/cs8409.h.orig $hda/codecs/cirrus/cs8409.h

    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      CFLAGS_MODULE="-DAPPLE_PINSENSE_FIXUP -DAPPLE_CODECS -DCONFIG_SND_HDA_RECONFIG=1 -Wno-unused-variable -Wno-unused-function" \
      CONFIG_SND_HDA_CODEC_CS8409=m \
      M=$hda \
      modules

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D build/hda/codecs/cirrus/snd-hda-codec-cs8409.ko \
      $out/lib/modules/${kernel.modDirVersion}/extra/snd-hda-codec-cs8409.ko
    runHook postInstall
  '';

  meta = {
    description = "Apple MacBook Pro CS8409 HDA audio driver for 2016/2017 models";
    license     = lib.licenses.gpl2Only;
    platforms   = [ "x86_64-linux" ];
  };
}

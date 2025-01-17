{ stdenv
, lib
, rustPlatform
, pkg-config
, elfutils
, zlib
, llvmPackages_16
, scx-common
}:

rustPlatform.buildRustPackage rec {
  pname = "scx-rustland";

  inherit (scx-common) src version;
  cargoRoot = "scheds/rust/scx_rustland";

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config llvmPackages_16.clang ];
  buildInputs = [ elfutils zlib ];
  LIBCLANG_PATH = "${llvmPackages_16.libclang.lib}/lib";

  postPatch = ''
    ln -s ${./Cargo.lock} scheds/rust/scx_rustland/Cargo.lock
  '';

  # Can't use sourceRoot because it will fail with lack of permissions in scx_utils
  preBuild = ''
    cd scheds/rust/scx_rustland
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp target/${stdenv.targetPlatform.config}/release/scx_rustland $out/

    runHook postInstall
  '';

  enableParallelBuilding = true;
  dontStrip = true;
  dontPatchELF = true;

  meta = with lib; {
    homepage = "https://bit.ly/scx_slack";
    description = "sched_ext schedulers and tools (scx_rustland portion)";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
  };
}

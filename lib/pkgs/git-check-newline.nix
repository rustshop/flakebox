{ stdenv, rustc }:

stdenv.mkDerivation {
  pname = "flakebox-git-check-newline";
  version = "0.1.0";
  dontUnpack = true;

  nativeBuildInputs = [ rustc ];

  buildPhase = ''
    runHook preBuild
    rustc --edition 2024 -D warnings -O ${./git-check-newline.rs} \
      -o flakebox-git-check-newline
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 flakebox-git-check-newline "$out/bin/flakebox-git-check-newline"
    runHook postInstall
  '';
}

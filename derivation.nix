{ stdenv, pkgs, fetchzip, fetchpatch, fetchgit, fetchurl }:
stdenv.mkDerivation {
  name = "scream-receiver-unix";

  src = fetchurl {
    url = "https://github.com/duncanthrax/scream/archive/refs/tags/3.7.tar.gz";
    sha256 = "0jl3x5kprsdcmf3l86hb4nawsgwsp1wwlms2hkx42lb98lgfwfc0";
  };
  buildInputs = with pkgs;
  [ cmake
    libpulseaudio
    pkg-config
  ];
  preConfigure = ''
    cd Receivers/unix
  '';

}

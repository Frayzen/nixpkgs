{
  lib,
  stdenv,
  fetchFromGitHub,
  gitUpdater,
  cmake,
  python3,
  rocmPackages,
  llvmPackages,

  hip-backend ? false,
  openmp-backend ? false,
  arch ? "",
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kokkos";
  version = "4.6.02";

  src = fetchFromGitHub {
    owner = "kokkos";
    repo = "kokkos";
    rev = finalAttrs.version;
    hash = "sha256-gpnaxQ3X+bqKiP9203I1DELDGXocRwMPN9nHFk5r6pM=";
  };

  propagatedBuildInputs =
    [ ]
    ++ lib.optionals (hip-backend || openmp-backend) [ rocmPackages.clang ]
    ++ lib.optionals hip-backend [
      rocmPackages.rocthrust
      rocmPackages.rocprim
      rocmPackages.rocmPath
    ]
    ++ lib.optionals openmp-backend [
      llvmPackages.openmp.dev
      llvmPackages.openmp
    ];

  nativeBuildInputs = [
    cmake
    python3
  ];

  cmakeFlags = [
    (lib.cmakeBool "Kokkos_ENABLE_SERIAL" true)
    (lib.cmakeBool "Kokkos_ENABLE_TESTS" true)
  ]
  ++ lib.optionals openmp-backend [
    (lib.cmakeBool "Kokkos_ENABLE_OPENMP" true)
    (lib.cmakeFeature "OpenMP_CXX_FLAGS" "-fopenmp")
    (lib.cmakeFeature "OpenMP_CXX_LIB_NAMES" "omp")
    (lib.cmakeFeature "OpenMP_omp_LIBRARY" "${llvmPackages.openmp}/lib/libomp.so")
    (lib.cmakeFeature "CMAKE_CXX_FLAGS" "-I${llvmPackages.openmp.dev}/include")
  ]
  ++ lib.optionals hip-backend [
    (lib.cmakeBool "Kokkos_ENABLE_HIP" true)
    (lib.cmakeFeature "CMAKE_CXX_COMPILER" "hipcc")
  ]
  ++ lib.optionals (arch != "") [ (lib.cmakeBool "Kokkos_ARCH_${arch}" true) ];

  postPatch = ''
    patchShebangs .
  '';

  doCheck = true;
  passthru.updateScript = gitUpdater { };

  meta = with lib; {
    description = "C++ Performance Portability Programming EcoSystem";
    homepage = "https://github.com/kokkos/kokkos";
    changelog = "https://github.com/kokkos/kokkos/blob/${finalAttrs.src.rev}/CHANGELOG.md";
    license = with licenses; [
      asl20
      llvm-exception
    ];
    maintainers = with maintainers; [
      Madouura
      Frayzen
    ];
    platforms = platforms.unix;
    broken = stdenv.hostPlatform.isDarwin;
  };
})

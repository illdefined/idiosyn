{ ... }: { config, lib, pkgs, ... }: {
  environment.memoryAllocator.provider = "mimalloc";
  environment.variables.MIMALLOC_LARGE_OS_PAGES = 1;
}

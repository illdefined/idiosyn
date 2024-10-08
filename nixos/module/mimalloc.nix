{ ... }: { config, lib, pkgs, ... }: {
  environment.memoryAllocator.provider = "mimalloc";
  environment.variables = {
    MIMALLOC_PURGE_DELAY = 50;
    MIMALLOC_PURGE_DECOMMITS = 0;
    MIMALLOC_ALLOW_LARGE_OS_PAGES = 1;
  };
}

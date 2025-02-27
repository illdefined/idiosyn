{ ... }: { config, lib, pkgs, ... }: {
  environment.memoryAllocator.provider = "mimalloc";
  environment.variables = {
    MIMALLOC_PURGE_DELAY = 50;
    MIMALLOC_PURGE_DECOMMITS = 0;
  };
}

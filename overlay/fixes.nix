{ ... }: final: prev: {
  redis = prev.redis.overrideAttrs ({
    doCheck = false;
  });
}

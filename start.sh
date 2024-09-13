#!/bin/bash
if [ -n "$FORCE_TAG" ]; then \
  config=~/suibase/workdirs/localnet/suibase.yaml
  echo '' >> $config
  echo 'force_tag: "${FORCE_TAG}"' >> $config
  localnet update
fi
localnet start &!
# wait a while
sleep 15
tail -f ~/suibase/workdirs/common/logs/suibase-daemon.log
#!/bin/bash
localnet start &! && \
sui-explorer-local start &! && \
tail -f ~/suibase/workdirs/common/logs/suibase-daemon.log
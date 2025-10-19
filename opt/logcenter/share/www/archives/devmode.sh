#!/bin/bash

export ZLC_ELASTIC_MAX_SIZE=200000000000
export ZLC_ARCHIVES_MAX_SIZE=1000000000000
export ZLC_INDICES_DB=$PWD/indices.db
export ZLC_ARCHIVES_DIR=$PWD
export ZLC_ENV=/dev/null
export ZLC_DEVMODE=1
export ZLCCLI=../../../bin/zlccli

"$@"

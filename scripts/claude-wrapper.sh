#!/usr/bin/env bash

# Patch IDE lockfiles before handing off to real claude.
#
# Claude Code deletes lockfiles where processAlive(pid) is false.
# Inside a container the host IDE's PID doesn't exist, so the lockfile
# gets nuked. We copy lockfiles from the read-only host mount and patch
# the pid to $$ — which becomes claude's own PID after exec, so the
# alive check always passes.

HOST_IDE_DIR="${HOME}/.ide-host"
LOCAL_IDE_DIR="${HOME}/.claude/ide"

mkdir -p "${LOCAL_IDE_DIR}"

for lockfile in "${HOST_IDE_DIR}"/*.lock; do
  [ -f "${lockfile}" ] || continue
  filename=$(basename "${lockfile}")
  python3 -c "
import json
with open('${lockfile}') as f:
    data = json.load(f)
data['pid'] = $$
with open('${LOCAL_IDE_DIR}/${filename}', 'w') as f:
    json.dump(data, f)
"
done

exec claude-real "$@"

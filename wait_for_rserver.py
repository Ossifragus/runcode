"""Wait until a talk2stat server is ready to accept connections.

Usage: python3 wait_for_rserver.py [LANG [DIR [TIMEOUT]]]
  LANG     language server to wait for: R, python, julia, matlab (default: R)
  DIR      working directory of the server (default: ./)
  TIMEOUT  seconds to wait before giving up (default: 120)
"""
import sys
import time
from talk2stat.talk2stat import client

lang    = sys.argv[1] if len(sys.argv) > 1 else 'R'
workdir = sys.argv[2] if len(sys.argv) > 2 else './'
timeout = int(sys.argv[3]) if len(sys.argv) > 3 else 120

for _ in range(timeout):
    if client(workdir, lang, '``` ```'):
        print(f'{lang} server ready')
        sys.exit(0)
    time.sleep(1)

sys.exit(f'ERROR: {lang} server did not become ready within {timeout} seconds')

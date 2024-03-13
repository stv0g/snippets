import subprocess
import logging

def get_unit_state(unit: str) -> dict:
    values = {}

    logging.debug("Get state of systemd unit: %s", unit)

    out = subprocess.check_output(['systemctl', 'show', unit])
    out = out.decode('utf-8')
    for line in out.split('\n'):
        if len(line) == 0:
            continue

        key, value = line.split('=', 1)
        values[key] = value

    return values

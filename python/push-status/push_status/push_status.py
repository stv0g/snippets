#!/usr/bin/env python3

import argparse
import os
import socket
import sys
import logging
import subprocess
from urllib.parse import urlencode

from push_status import monitors, systemd


def push(url: str, token: str, status: str = 'up', msg: str = 'OK', ping: str = ''):
    args = {
        'status': status,
        'msg': msg,
        'ping': ping
    }

    url = f'{url}/api/push/{token}?' + urlencode(args)

    logging.debug('Push status: %s', url)

    resp = subprocess.check_output(['curl', '-s', url])
    logging.info("Response: %s", resp.decode('utf-8'))


def main():
    logging.basicConfig(level=logging.DEBUG)

    default_unit = os.environ.get('MONITOR_UNIT', '')
    default_host = socket.getfqdn()

    parser = argparse.ArgumentParser()
    parser.add_argument('--clear-cache', '-c', action='store_true', help='Clear cache')
    parser.add_argument('--username', '-u', type=str, required=True)

    password = parser.add_mutually_exclusive_group(required=True)
    password.add_argument('--password', '-p', type=str)
    password.add_argument('--password-file', type=str)

    parser.add_argument('--url', '-U', type=str, default='https://status.0l.de')
    parser.add_argument('host_unit', type=str, default=f'{default_host}/{default_unit}')

    args = parser.parse_args()

    if args.clear_cache:
        monitors.cache.clear()

    if args.password_file is not None:
        with open(args.password_file) as f:
            password = f.readline().strip()
    else:
        password = args.password

    try:
        host, unit = args.host_unit.split('/')
    except:
        host = default_host
        unit = args.host_unit

    state = systemd.get_unit_state(unit)

    desc = state.get('Description', 'Unknown unit')
    start_ts = state.get('ActiveEnterTimestamp')

    start = int(state.get('ActiveEnterTimestampMonotonic', 0))
    stop = int(state.get('ActiveExitTimestampMonotonic', 0))

    duration = (stop - start) * 1e-6
    rc = int(state.get('ExecMainStatus', '-1'))
    state = 'up' if rc == 0 else 'down'
    msg = f'Execution of {desc} started at {start_ts} finished after {duration} s with exit code {rc}'

    logging.debug("State: state=%s, rc=%d, duration=%f", state, rc, duration)

    monitor = monitors.get_systemd(args.url, args.username, password, host, unit)
    if monitor is None:
        logging.error("No monitor found for: %s/%s", host, unit)
        sys.exit(1)

    logging.info("Monitor: %s", monitor.get('name'))

    push(args.url, monitor.get('pushToken'), state, msg, duration*1e3)

    return 0


if __name__ == '__main__':
    main()

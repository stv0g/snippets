import argparse
from datetime import datetime
import os

def parse_arguments(with_subcommands=True):
    def valid_date(s):
        try:
            return datetime.strptime(s, "%Y-%m")
        except ValueError:
            msg = "Not a valid date: '{0}'.".format(s)
            raise argparse.ArgumentTypeError(msg)

    parser = argparse.ArgumentParser('accelerated_stats',
        description='Get port stats from Accelerated Customer Interface (e.g. interface.datafabrik.de)')
    parser.add_argument('--debug', '-d', type=bool, default=False)
    parser.add_argument('--format', '-f', choices=['raw', 'json'], default='json')
    parser.add_argument('--field', '-F', type=str)
    parser.add_argument('--no-coerce', '-c', action='store_true', default=False)
    parser.add_argument('--unit-volume', type=str, default='B')
    parser.add_argument('--unit-speed', type=str, default='bit/s')
    parser.add_argument('--unit-time', type=str, default='s')
    parser.add_argument('--kdnummer', '-u', type=str, default=os.environ.get('KDNUMMER'))
    parser.add_argument('--password', '-p', type=str, default=os.environ.get('PASSWORD'))
    parser.add_argument('--url', '-U', type=str, default='https://interface.datafabrik.de/')
    parser.add_argument('--server', '-s', type=int)
    parser.add_argument('--date', '-D', type=valid_date, default=datetime.now())
    parser.add_argument('--prefix', '-P', type=str, default='accelerated_')

    if with_subcommands:
        parser.add_argument('cmd', metavar='CMD', choices=['stats', 'usage', 'usage_sum', 'servers'])

    return parser.parse_args()

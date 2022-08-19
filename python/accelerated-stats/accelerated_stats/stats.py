#!/bin/env python3

import os
import sys
import json
from datetime import datetime

from accelerated_stats import utils
from accelerated_stats.tenant import Tenant

def converter(o):
    if isinstance(o, datetime):
        return o.strftime('%Y-%m-%d')


def main():

    args = utils.parse_arguments()

    args.coerce = not args.no_coerce

    args_dict = vars(args)

    acc = Tenant(**args_dict)

    servers = acc.get_servers()
    if args.server:
        servers = filter(lambda s: s.id == args.server, servers)

    if args.cmd == 'servers':
        out = [s.as_dict() for s in servers]
    else:
        out = []

        for server in servers:
            if args.cmd == 'stats':
                sout = server.get_stats()
            elif args.cmd == 'usage':
                sout = {
                    'usage': server.get_usage(args.date)
                }
            elif args.cmd == 'usage_sum':
                usage = server.get_usage(args.date)

                usage_sum = {
                    k: sum([ d[k] for d in usage ]) for k in ['in', 'out']
                }

                usage_sum['total'] = usage_sum['in'] + usage_sum['out']

                sout = {
                    'usage_sum': usage_sum
                }

            out.append({
                **server.as_dict(),
                **sout
            })

    if args.format == 'json':
        json.dump(out, sys.stdout, indent=4, default=converter)
        sys.stdout.write('\n')
    elif args.format == 'raw':
        if out is list:
            out.keys().join(',')
            for l in out:
                l.values().join(',')

        elif out is dict:
            if args.field:
                print(out[args.field])
            else:
                for k, v in out.enumerate():
                    print(f'{k}: {v}')

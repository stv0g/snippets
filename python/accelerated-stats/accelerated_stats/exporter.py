from flask import Flask, Response

from accelerated_stats.tenant import Tenant
from accelerated_stats.utils import parse_arguments

args = parse_arguments(with_subcommands=False)
args_dict = vars(args)

acc = Tenant(**args_dict)
app = Flask(__name__)

app.config['DEBUG'] = args.debug

if args.server:
    servers = [ args.server ]
else:
    servers = acc.get_servers()

@app.route('/healthz')
def healthz():
    return Response('OK', mimetype='text/plain')

@app.route('/metrics')
def metrics():
    metrics = []

    for server in servers:
        stats = server.get_stats()

        for k, v in stats.items():
            if k == 'port':
                continue

            t = [f'{p}="{q}"' for p, q in server.as_dict().items()]
            t = ','.join(t)

            metrics.append(f'{args.prefix}{k}{{{t}}} {v}')

    resp = '\n'.join(metrics)

    return Response(resp, mimetype='text/plain')

def main():
    app.run(host='::')

import requests
from datetime import datetime
from lxml import etree
from pint import UnitRegistry
import re
import io

ureg = UnitRegistry()
ureg.define('MBit = Mbit')
ureg.define('KBit = kbit')
ureg.define('MB = megabyte')
ureg.define('KB = kilobyte')
ureg.define('GB = gigabyte')

class Server:

    def __init__(self, tenant, id, switch=None, port=None, name=None, hostname=None):
        self.tenant = tenant
        self.id = id
        self.switch = switch
        self.port = port
        self.name = name
        self.hostname = hostname

    def get_usage(self, date):
        return self.tenant._get_usage(self.id, date)

    def get_stats(self):
        return self.tenant._get_stats(self.id)

    def as_dict(self):
        srv = {
            'id': self.id,
            'tenant': int(self.tenant.kdnummer)
        }

        if self.switch:
            srv['switch'] = self.switch

        if self.port:
            srv['port'] = self.port

        if self.name:
            srv['name'] = self.name

        if self.hostname:
            srv['hostname'] = self.hostname

        return srv


class Tenant:

    STATS_FIELDS = {
        # 'port':             1,
        'max_speed':        2,
        'switch_uptime':    3,
        'incoming':         4,
        'outgoing':         5,
        'sum':              6,
        'usage_95perc':     7,
        'usage_avg':        8,
        'current_in':       10,
        'current_out':      11
    }

    XPATH_CONTENT = '//*[@id="accelerated-layout-container-content"]'

    XPATH_USAGE_TABLE = XPATH_CONTENT + '/table'
    XPATH_SERVER_TABLE = XPATH_USAGE_TABLE
    XPATH_STATS_TABLE = XPATH_CONTENT + '/table[3]/tr[1]/td/table'
    XPATH_SERVER_ROWS = XPATH_SERVER_TABLE + '/tr[position() > 2 and position() < last() and position() mod 2]'
    XPATH_FIELDS = { k: f'tr[{i}]/td[2]' for k, i in STATS_FIELDS.items() }

    def __init__(self, **kwargs):
        self.sess = requests.Session()

        self.coerce      = kwargs.get('coerce', True)
        self.url         = kwargs.get('url')
        self.kdnummer    = kwargs.get('kdnummer')
        self.password    = kwargs.get('password')

        self.unit_volume = kwargs.get('unit_volume', 'TiB')
        self.unit_speed  = kwargs.get('unit_speed', 'MBit/s')
        self.unit_time   = kwargs.get('unit_time', 's')

        self.do_login()

    def as_dict(self):
        return {
            'kdnummer': self.kdnummer
        }

    @property
    def login_url(self):
        return f'{self.url}/verify.php'

    @property
    def server_url(self):
        return f'{self.url}/CServer.php'

    def usage_url(self, server, date):
        d = date.strftime('%Y.%m')
        return f'{self.server_url}?action=detailUsage&id={server}&date={d}'

    def stats_url(self, server):
        return f'{self.server_url}?action=stats&id={server}'

    def do_login(self):

        payload = {
            'kdnummer': self.kdnummer,
            'passwort': self.password,
            'Login': 'Login',
            'url': ''
        }

        r = self.sess.post(self.login_url, data=payload)


    def get_servers(self):
        r = self.sess.get(self.server_url + '?switchPort=show')

        parser = etree.HTMLParser()
        root = etree.parse(io.StringIO(r.text), parser)
        table = root.xpath(self.XPATH_USAGE_TABLE)[0]
        rows = root.xpath(self.XPATH_SERVER_ROWS)

        servers = []

        for row in rows:
            anchor = row.xpath('td[3]/a')[0]
            href = anchor.get('href')

            match = re.match('CServer.php\?action=stats&id=([0-9]+)', href)
            if match:
                server_id = int(match.group(1))

                server = {
                    'id': server_id
                }

                name = row.xpath('td[2]')
                if name:
                    server['name'] = re.sub(r'\s+|\|', ' ', name[0].text).strip()

                hostname = row.xpath('td[2]/u/font')
                if len(hostname) > 0:
                    server['hostname'] = hostname[0].text.strip()

                swport_row = row.getnext()
                if swport_row is not None:
                    swport = swport_row.xpath('td[2]/table/tr/td[2]/font')
                    if len(swport) > 0:
                        switch, port = swport[0].text.strip().split(' -> ')
                        server['port'] = port
                        server['switch'] = switch

                servers.append(Server(self, **server))

        return servers

    def _get_usage(self, server_id, date):
        r = self.sess.get(self.usage_url(server_id, date))

        parser = etree.HTMLParser()
        root = etree.parse(io.StringIO(r.text), parser)
        table = root.xpath(self.XPATH_USAGE_TABLE)[0]
        rows = table.xpath('tr')

        data = []

        for row in rows[1:]:
            columns = row.xpath('td')

            data_row = {
                'date': datetime.strptime(columns[2].xpath('b')[0].text.strip(), '%d.%m.%Y'),
                'in':   columns[3].text.strip(),
                'out':  columns[4].text.strip()
            }

            if self.coerce:
                target_unit = ureg.parse_expression(self.unit_volume)

                for f in [ 'in', 'out' ]:
                    d = data_row[f]
                    d = ureg.parse_expression(d)
                    d = d.to(target_unit).magnitude

                    data_row[f] = d

            data.append(data_row)

        return data

    def _get_stats(self, server_id):
        r = self.sess.get(self.stats_url(server_id))

        parser = etree.HTMLParser()
        root = etree.parse(io.StringIO(r.text), parser)
        table = root.xpath(self.XPATH_STATS_TABLE)[0]

        data = { k: table.xpath(p)[0].text for k, p in self.XPATH_FIELDS.items() }

        if self.coerce:
            target_units = {
                'switch_uptime': ureg.parse_expression(self.unit_time),
                'incoming':      ureg.parse_expression(self.unit_volume),
                'outgoing':      ureg.parse_expression(self.unit_volume),
                'sum':           ureg.parse_expression(self.unit_volume),
                'max_speed':     ureg.parse_expression(self.unit_speed),
                'usage_95perc':  ureg.parse_expression(self.unit_speed),
                'usage_avg':     ureg.parse_expression(self.unit_speed),
                'current_in':    ureg.parse_expression(self.unit_speed),
                'current_out':   ureg.parse_expression(self.unit_speed)
            }

            for f in [ 'incoming', 'outgoing', 'sum' ]:
                data[f] = re.sub(r"(K|M|G|T|)B$", r"\1iB", data[f])

            data['switch_uptime'] = re.sub(r"(\d+) days, (\d+):(\d+):(\d+).(\d+)", r"\1 days + \2 hours + \3 minutes + \4 seconds + \5 centiseconds", data['switch_uptime'])

            coerced_data = { k: ureg.parse_expression(v) for k, v in data.items() if k != 'port' }
            converted_data = { k: coerced_data[k].to(target_units[k]).magnitude for k, v in coerced_data.items() }

            data = { **data, **converted_data }

        return data

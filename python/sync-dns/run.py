import dns.resolver
import dns.zone
import dns.query
import dns.rdatatype
import dns.reversename
import dns.name
import ipaddress

import itertools
import pynetbox

MYNETS_V4 = [
    '172.23.156.0/23',
    '192.168.178.0/24'
]

MYNETS_V6 = [
    '2a09:11c0:200::/44'
]

ZONES = [
    '0l.de.'
]

RZONES_V4 = [
    '156.23.172.in-addr.arpa.',
    '157.23.172.in-addr.arpa.',
    '178.168.192.in-addr.arpa.'
]

RZONES_V6 = [
    '0.2.0.0.c.1.1.9.0.a.2.ip6.arpa.'
]

master_name = 'ipa-0.edgy.vms.0l.de'
master_answer = dns.resolver.resolve(master_name, 'A')

NS = master_answer[0].address


def is_mine_v4(ip):
    ip = ipaddress.IPv4Address(ip)

    for mynet in MYNETS_V4:
        if ip in ipaddress.IPv4Network(mynet):
            return True

    return False


def is_mine_v6(ip):
    ip = ipaddress.IPv6Address(ip)

    for mynet in MYNETS_V6:
        if ip in ipaddress.IPv6Network(mynet):
            return True

    return False


def get_ips(zones, rdtype='A'):
    rdtype = dns.rdatatype.from_text(rdtype)

    ips = {}

    for zone in zones:
        zone = dns.name.from_text(zone)

        x = dns.query.xfr(NS, zone)
        z = dns.zone.from_xfr(x)

        for name, ttl, rdata in z.iterate_rdatas(rdtype):
            name = name.derelativize(zone).to_text()
            addr = rdata.address

            ips[name] = addr

    return ips


def get_ptrs(rzones):
    ptrs = {}

    for rzone in rzones:
        rzone = dns.name.from_text(rzone)

        x = dns.query.xfr(NS, rzone)
        z = dns.zone.from_xfr(x)
            
        for name, ttl, rdata in z.iterate_rdatas(dns.rdatatype.PTR):
            name = name.derelativize(rzone)
            addr = dns.reversename.to_address(name)

            fname = rdata.target

            ptrs[addr] = fname.to_text()

    return ptrs


def get_netbox_ips():
    nb = pynetbox.core.api.Api('https://netbox.0l.de', 'f3b10d7f8d5f573ac69042df8d5242aef2f90d1d')

    ips = nb.ipam.ip_addresses.all()

    return { ip.address: ip.dns_name for ip in ips }



nb_ips = get_netbox_ips()

for ip in dict(filter(lambda ip: ip[1] == '', nb_ips.items())):
    print('Missing DNS name in Netbox: ' + ip)

afs = [
    (get_ips(ZONES, 'A'),    get_ptrs(RZONES_V4), is_mine_v4),
    (get_ips(ZONES, 'AAAA'), get_ptrs(RZONES_V6), is_mine_v6),
]

for ips, ptrs, is_mine in afs:
    for fqdn, ip in ips.items():
        try:
            if ptrs[ip] != fqdn:
                print(f'PTR Mismatch: PTR of {fqdn} is {ptrs[ip]} IP: {ip}')
        except KeyError:
            if is_mine(ip):
                print(f'Missing PTR for {fqdn} IP: {ip}')

        try:
            if nb_ips[ip] != fqdn:
                print(f'Name mismatch in Netbox: {nb_ips[ip]} != {fqdn}')
        except KeyError:
            print(f'Missing Netbox IP: {ip}')

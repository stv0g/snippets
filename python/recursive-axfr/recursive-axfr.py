import dns.resolver
import dns.zone
import dns.query
import dns.rdatatype
import dns.reversename
import dns.name

import sys

ZONES = ['0l.de', 'steffenvogel.de', 'dn42.org', 'vogel.cc', 'noteblok.net', 'chaos.family', '0l.dn42']

master_name = 'ipa-0.edgy.vms.0l.de'
master_answer = dns.resolver.resolve(master_name, 'A')

NS = master_answer[0].address

def get_names(zone, rdtypes=['A', 'AAAA', 'CNAME', 'NS']):
    names = set()

    zone = dns.name.from_text(zone)

    try:
        x = dns.query.xfr(NS, zone)
        z = dns.zone.from_xfr(x)

        for rdtype in rdtypes:
            rdtype = dns.rdatatype.from_text(rdtype)

            for name, ttl, rdata in z.iterate_rdatas(rdtype):
                fqdn = name.derelativize(zone).to_text(True)

                if rdtype == dns.rdatatype.NS and len(name) > 0:
                    names |= get_names(fqdn)
                elif not name.is_wild():
                    names.add(fqdn)

    except dns.xfr.TransferError as e:
        print(f'{e}: {zone}', file=sys.stderr)

    return names

def main():

    names = set()
    for zone in ZONES:
        names |= get_names(zone)

    print('\n'.join(sorted(names)))


if __name__ == '__main__':
    main()

#!/usr/bin/env python

import owncloud
import requests
import re
import sys
import posixpath
import urlparse

import xml.etree.ElementTree as ET

from optparse import OptionParser
from tidylib import tidy_document

PATH = 'Master.ET-IT-TI/'
USER = ''
PASS = ''
URL = 'https://rwth-aachen.sciebo.de'

TITLES = ['Wirt.-Ing.', 'Priv.-Doz.', 'E.h.', 'Ph. D.', 'Univ.', 'habil.', 'Dipl.', 'Prof.', 'Dr', 'Ing', 'rer.', 'dent.', 'paed.', 'nat.', 'phil.', 'Inform.', 'apl', 'Kff.', 'Kfm.', 'med.', 'B. Sc.', 'M. Sc.', 'B. A.', 'M. A.', 'RWTH', 'Chem', ',', '.', '-', '/', '\\']
WHITELIST = ['Z608AD@rwth-aachen.de', '121EHT@rwth-aachen.de', '6ANU61@rwth-aachen.de', 'FTD971@rwth-aachen.de', 'NB92H4@rwth-aachen.de']

def strip_ns(xml_string):
    return re.sub('xmlns="[^"]+"', '', xml_string)
    
def simplify_name(name):
    for token in TITLES:
        name = name.replace(token, " ")
    
    name = re.sub("\s\s+", " ", name)
    name = re.sub("^\s+", "", name)
    name = re.sub("\s+$", "", name)
    
    return name

# At least one lastname and one firstname have to match
def check_employee(lastname, firstname):
    firstname = simplify_name(firstname)
    lastname = simplify_name(lastname)
    
    employees = get_employees(lastname, firstname)
    critical = [ ]
    
    firstnames = set(firstname.lower().split(" "))
    lastnames  = set(lastname.lower().split(" "))
    
    for employee in employees:
        employee2 = set(simplify_name(employee).lower().split(" "))
        isect1 = employee2.intersection(firstnames)
        isect2 = employee2.intersection(lastnames)
        if len(isect1) and len(isect2):
            critical.append(employee)
            
    return critical
            
def get_employees(lastname, firstname):
    payload = { 'find' : lastname }
    res = requests.get('https://www.campus.rwth-aachen.de/rwth/all/lecturerlist.asp', params=payload)
    if res.status_code == 200:
        persons = [ ]
        
        document, errors = tidy_document(res.content, options={'numeric-entities': 1, 'output_xhtml': 1})
        tree = ET.fromstring(strip_ns(document))
        
        try:
            filename = posixpath.basename(urlparse.urlsplit(res.url).path)
            if filename == 'lecturer.asp':
                fullname = tree.find('body/table[1]/tr[3]//tr[2]/td[2]').text.strip()
                unit = tree.find("body/table[2]//td[@class='h3']/a").text.strip()
            
                persons.append(fullname)

            elif filename == 'lecturerlist.asp':
                links = [ ]
                for cell in tree.findall('body/table[2]//td[3]/table[2]//td[1]/a'):
                    if cell is not None:
                        fullname = cell.text.strip()
                        persons.append(fullname)
            else:
                raise Exception
        except:
            print "===> WARNING: failed to get employee list for: %s, %s" % (firstname, lastname)
        
        return persons

def get_share(self, id):
    data = 'shares/%u' % id

    res = self._Client__make_ocs_request(
        'GET',
        self.OCS_SERVICE_SHARE,
        data
    )
    if res.status_code == 200:
        tree = ET.fromstring(res.content)
        self._Client__check_ocs_status(tree)
        element = tree.find('data').find('element')
        share_attr = {}
        for child in element:
            key = child.tag
            value = child.text
            share_attr[key] = value
        return share_attr
    raise ResponseError(res)


def add_shares(options, oc, shares):
    # Get list of existing shares
    existing = [ ]
    for share in shares:
        existing.append(share['share_with'])

    for line in sys.stdin:
        id = line.strip()
        
        match = re.match('[A-Z0-9]{6}@rwth-aachen.de', id)
        if match:
            if id in existing:
                share = (item for item in shares if item['share_with'] == id).next()
                print '%s already is in share list' % share['share_with_displayname']
                continue

            try:
                share = oc.share_file_with_user(options.path, id, perms=options.perms)
                details = get_share(oc, share.share_id)
                
                match = re.match('([^,]*), ([^(]*) \(', details['share_with_displayname'])
                if match:
                    lastname = match.group(1)
                    firstname = match.group(2)
                    critical = check_employee(lastname, firstname)
                    if len(critical):
                        print "===> ATTANTION: %s maybe an employee!! Add manually!!!" % details['share_with_displayname']
                        print "     We found these employees with similar names in Campus Office:"
                        for employee in critical:
                            print '    %s' % employee
                        continue
                
                print 'Added %s' % details['share_with_displayname']

            except owncloud.ResponseError as e:
                print 'Failed to add: %s' % e.response.content.strip()

def check_shares(options, oc, shares):
    for share in shares:
        if share['share_with'] in WHITELIST:
            continue
        if 'share_with_displayname' not in share.keys():
            print '===> ATTENTION: %s has no display name! You should remove it manually!'
            continue
    
        match = re.match('([^,]*), ([^(]*) \(', share['share_with_displayname'])
        if match:
            lastname = match.group(1)
            firstname = match.group(2)
            critical = check_employee(lastname, firstname)
        
            if len(critical):
                print "===> ATTENTION: %s maybe an employee!!!" % share['share_with_displayname']
                print "     We found these employees with similar names in Campus Office:"
                for employee in critical:
                    print '    %s' % employee
        else:
            raise Exception("Failed to match share_id")
        
def list_shares(options, oc, shares):
    print "Perm, Name, Added By"

    for share in shares:
        if int(share['permissions']) >= options.perms:
            if 'displayname_owner' not in share.keys():
                share['displayname_owner'] = '!!unknown!!'
            if 'share_with_displayname' not in share.keys():
                share['share_with_displayname'] = '!!unknown!!'
            
            print "%s%s%s" % (share['permissions'].ljust(3), share['share_with_displayname'].ljust(65).encode('utf-8'), share['displayname_owner'])

    print '=== Total: %u' % len(shares)

if __name__ == "__main__":
    print "## Owncloud / Sciebo share manager v0.1"
    print
    
    parser = OptionParser(usage="Usage: %prog [options] (list [admin]|add|del|check)")
    parser.add_option("-P", "--path",  dest="path",  default=PATH, help="path to share", metavar="PATH")
    parser.add_option("-U", "--url",   dest="url",   default=URL,  help="OwnCloud url", metavar="URL")
    parser.add_option("-u", "--user",  dest="user",  default=USER, help="OwnCloud username", metavar="USER")
    parser.add_option("-p", "--pass",  dest="password", default=PASS, help="OwnCloud password", metavar="PASS")
    parser.add_option("-a", "--perm",  type="int", dest="perms", default=5,    help="for new shares or as filter for list command", metavar="PERM")

    (options, args) = parser.parse_args()

    # Connect
    try:
        oc = owncloud.Client(options.url)
        oc.login(options.user, options.password)

        # Get list of already existing IDs
        shares = oc.get_shares(options.path, reshares=True)

        if len(args) >= 1:
            command = args[0]
        else:
            command = 'list'

        if   command == 'add':
            add_shares(options, oc, shares)
        elif command == 'list':
            list_shares(options, oc, shares)
        elif command == 'check':
            check_shares(options, oc, shares)
        
    except owncloud.ResponseError as e:
        print 'OwnCloud: %s' % e.response.content.strip()

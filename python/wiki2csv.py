#!/usr/bin/python3
# -*- tab-width: 2; indent-tabs-mode: t; -*-

# Copyright 2012 Jan Kanis
# License: GPL-3.0


# wiki2csv
#
# An explanation of this program is given in the accompanying README file.
# This program is maintained at http://www.bitbucket.org/JanKanis/wiki2csv/
# If you find any bugs, you can report them there.
# For command line options, see the help output of "wiki2csv.py --help".
# See http://en.wikipedia.org/wiki/Help:Wikitable for the wikitable syntax.


from collections import namedtuple
import sys, re, os.path, argparse, csv


Lexeme = namedtuple('Lexeme', 'type data raw')

# the different lexeme types in the wiki table syntax
class PreTable (object): # All text before the table starts gets this type
	pass
class TableStart (object):
	pass
class TableCaption (object):
	pass
class TableRow (object):
	pass
class TableHeader (object):
	pass
class TableHeaderSinglerow (TableHeader):
	pass
class TableHeaderContinued (TableHeader):
	pass
class TableData (object):
	pass
class TableDataSinglerow (TableData):
	pass
class TableDataContinued (TableData):
	pass
class TableEnd (object):
	pass

# what should happen for each type
actions = dict(
	# Store the item on a row of its own
	singlerow=(TableStart, TableCaption, TableEnd),
	# Store the data without the sytax marker
	data=(TableData,),
	# Store the full raw text
	raw=(TableHeader,)
)

# associations between wiki syntax and types
wikitypes = [
		('{|', TableStart),
		('|+', TableCaption),
		('|-', TableRow),
		('|}', TableEnd),
		('!', TableHeader),
		('|', TableData),
	]


# a generator that returns Lexemes. Input is a single string with a wikitable.
def wikitableparse(table):
	stable = table.split('\n')
	if not stable[-1]:
		del stable[-1]
	current = dict(type=PreTable, data='', raw='')

	for row in stable:
		srow = row.lstrip()
		for marker, type in wikitypes:
			if srow.startswith(marker):
				if current['type'] != PreTable:
					yield Lexeme(**current)
				current = dict(type=type, data=srow[len(marker):], raw=row)

				# process multiple cells on one line
				if current['type'] == TableData and '||' in current['data']:
					rows = current['raw'].split('||')
					yield Lexeme(type=TableDataSinglerow, data=rows[0].lstrip()[2:], raw=rows[0])
					for r in rows[1:-1]:
						yield Lexeme(type=TableDataContinued, data=r, raw='||'+r)
					current = dict(type=TableDataContinued, data=r, raw='||'+r)

				# same for multiple header cells on one line
				if current['type'] == TableHeader and '!!' in current['data']:
					rows = current['raw'].split('!!')
					yield Lexeme(type=TableHeaderSinglerow, data=rows[0].lstrip()[2:], raw=rows[0])
					for r in rows[1:-1]:
						yield Lexeme(type=TableHeaderContinued, data=r, raw='!!'+r)
					current = dict(type=TableHeaderContinued, data=r, raw='!!'+r)

				# Don't try to match again if we already hava a match
				break

		# continuation of previous lexeme on next line
		else:
			current['data'] += '\n' + row

	yield Lexeme(**current)


def wiki2csv(wikifile, csvfile):
	writer = csv.writer(csvfile)
	parser = wikitableparse(wikifile.read())
	row = []
	for lex in parser:
		if lex.type == TableRow:
			if row: writer.writerow(row)
			row = []
		elif lex.type in actions['singlerow']:
			if row: writer.writerow(row)
			writer.writerow([lex.raw])
			row = []
		elif lex.type in actions['data']:
			row.append(lex.data)
		elif lex.type in actions['raw']:
			row.append(lex.raw)
	if row:
		writer.writerow(row)


rawtypes = re.compile('|'.join((re.escape(marker) for marker, type in wikitypes
		if type in actions['raw'])))
singlerowtypes = re.compile('|'.join((re.escape(marker) for marker, type in wikitypes
		if type in actions['singlerow'])))

def parsecsv(csvfile):
	reader = csv.reader(csvfile)
	newrow = False
	for line in reader:
		for cell in line:
			if singlerowtypes.match(cell):
				yield cell
				break
			elif rawtypes.match(cell):
				yield cell
			elif len(cell) and cell[0] in '-+}':
				# Avoid a cornercase where a normal data cell has e.g. '-1' as content,
				# which would result in a new row marker
				yield '| '+cell
			else:
				yield '|'+cell
		if not singlerowtypes.match(cell):
			yield '|-'

def csv2wiki(csvfile, wikifile):
	for cell in parsecsv(csvfile):
		wikifile.write(cell+'\n')


def main():

	progname = os.path.basename(sys.argv[0])
	progname_cooked = os.path.splitext(progname)[0]

	# to show the correct help text
	towikidefault = tocsvdefault = ''
	if progname_cooked == 'csv2wiki':
		towikidefault = '(default for {}) '.format(progname)
		description = "Convert SOURCE containing a table CSV format to Mediawikis wikitable syntax in DEST. Do the reverse if --tocsv is given."
	else:
		tocsvdefault = '(default for {}) '.format(progname)
		description = "Convert SOURCE containing a table in Mediawikis wikitable syntax to Excel-readable CSV in DEST. Do the reverse if --towiki is given."

	# parse arguments
	parser = argparse.ArgumentParser(description=description)
	parser.add_argument('-v', '--verbose', action='store_true', help="be more verbose")

	direction = parser.add_mutually_exclusive_group()
	direction.add_argument('--tocsv', '-c', action='store_true',
		help=tocsvdefault+"Convert SOURCE from wikitable format to CSV in DEST")
	direction.add_argument('--towiki', '-w', action='store_true',
		help=towikidefault+"Convert SOURCE from CSV format back to wikitable format in DEST")

	parser.add_argument('source', metavar='SOURCE', type=argparse.FileType('r'), nargs='?', default=sys.stdin,
		help="The input file to read from. Omit or use '-' to read from stdin")
	parser.add_argument('dest', metavar='DEST', type=argparse.FileType('w'), nargs='?', default=sys.stdout,
		help="The file to write output to. Omit or use '-' to write to stdout")

	args = parser.parse_args()

	if args.towiki:
		direction = 'towiki'
	elif args.tocsv:
		direction = 'tocsv'
	elif progname_cooked == 'csv2wiki':
		direction = 'towiki'
	else:
		direction = 'tocsv'

	if args.verbose:
		print >>sys.stderr, 'direction=%s\n' % direction, 'source=%s\n' % args.source, 'dest=%s\n' % args.dest,

	if direction == 'towiki':
		csv2wiki(args.source, args.dest)
	else:
		wiki2csv(args.source, args.dest)

	if args.verbose:
		print >>sys.stderr, 'Conversion completed'


if __name__ == '__main__':
	main()

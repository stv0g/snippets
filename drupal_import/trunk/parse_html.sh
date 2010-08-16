#!/bin/sh

find webpage/ -name *.html -exec php parse_html.php {} \;
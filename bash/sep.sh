#!/bin/bash


for file in *.PDF; do
	name=$(basename -s .PDF $file)

	pdfseparate $file "$name-%d.pdf"
done

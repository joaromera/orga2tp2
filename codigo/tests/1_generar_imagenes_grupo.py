#!/usr/bin/env python

from libtest import *
import subprocess
import sys

# Este script crea las multiples imagenes de prueba a partir de unas
# pocas imagenes base.


IMAGENES=["lena.bmp"]

assure_dirs()

#sizes=['200x200', '204x204', '208x208', '256x256', '512x512', '1024x768']

sizes=['16x16']

i = 16
while i < 1024:
	i += 8
	sizes += ["{}x{}".format(i,i)]


for filename in IMAGENES:
	print(filename)
	j = 1
	for size in sizes:
		sys.stdout.write("  " + size)
		name = filename.split('.')
		file_in  = "./img_a_generar/" + filename
		file_out = "./img_generadas/" + name[0] + "." + str(j).zfill(3) + "." + size + "." + name[1]
		resize = "convert -resize " + size + "! " + file_in + " " + file_out
		subprocess.call(resize, shell=True)
		j += 1

print("")

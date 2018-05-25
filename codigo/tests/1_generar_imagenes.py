#!/usr/bin/env python

from libtest import *
import subprocess
import sys

# Este script crea las multiples imagenes de prueba a partir de unas
# pocas imagenes base.


IMAGENES=["lena.bmp"]

assure_dirs()

sizes=['200x200', '204x204', '208x208', '256x256', '512x512', '1024x768']

# Imagenes menores a 128x128 dan errores en blit por requerimentos del filtro
# sizes=['16x16','32x32','64x64','128x128','256x256','512x512','1024x1024','2048x2048','4096x4096']

for filename in IMAGENES:
	print(filename)

	for size in sizes:
		sys.stdout.write("  " + size)
		name = filename.split('.')
		file_in  = DATADIR + "/" + filename
		file_out = TESTINDIR + "/" + name[0] + "." + size + "." + name[1]
		resize = "convert -resize " + size + "! " + file_in + " " + file_out
		subprocess.call(resize, shell=True)

print("")

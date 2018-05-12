#include <math.h>

#include "../tp2.h"

#define PI 			3.1415
#define RADIUS 		35
#define WAVELENGTH 	64
#define TRAINWIDTH 	3.4

float sin_taylor (float x) {
	float x_3 = x*x*x;
	float x_5 = x*x*x*x*x;
	float x_7 = x*x*x*x*x*x*x;

	return x-(x_3/6.0)+(x_5/120.0)-(x_7/5040.0);
}

float profundidad (int x, int y, int x0, int y0) {
	float dx = x - x0;
	float dy = y - y0;

	float dxy = sqrt(dx*dx+dy*dy);

	float r = (dxy-RADIUS)/WAVELENGTH ;
	float k = r-floor(r);
	float a = 1.0/(1.0+(r/TRAINWIDTH)*(r/TRAINWIDTH));

	float t = k*2*PI-PI;

	float s_taylor = sin_taylor(t);

	return a * s_taylor;
}

float saturar(float color) {
	if (color < 0) {
		color = 0;
	} else if (color > 255) {
		color = 255;
	}
	return color;
}

void ondas_c (
	unsigned char *src,
	unsigned char *dst,
	int width,
	int height,
	int src_row_size,
	int dst_row_size,
	int x0,
	int y0
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;

	for (int i = 0; i < height; i++) {
		for (int j = 0; j < width * 4; j += 4) {
			float azul = profundidad(i, j / 4, y0, x0) * 64 + src_matrix[i][j];
			azul = saturar(azul);
			dst_matrix[i][j] = azul;

			float verde = profundidad(i, j / 4, y0, x0) * 64 + src_matrix[i][j + 1];
			verde = saturar(verde);
			dst_matrix[i][j + 1] = (unsigned char) verde;

			float rojo = profundidad(i, j / 4, y0, x0) * 64 + src_matrix[i][j + 2];
			rojo = saturar(rojo);
			dst_matrix[i][j + 2] = (unsigned char) rojo;
		}
	}
}
#define max(a, b) ((a)>(b))?(a):(b)

void monocromatizar_inf_c (
	unsigned char *src, 
	unsigned char *dst, 
	int width, 
	int height, 
	int src_row_size, 
	int dst_row_size
) {
	unsigned char (*src_matrix)[src_row_size] = (unsigned char (*)[src_row_size]) src;
	unsigned char (*dst_matrix)[dst_row_size] = (unsigned char (*)[dst_row_size]) dst;
	for (int i = 0; i < height; i++) {
		for (int j = 0; j < width * 4; j+=4) {
			int grey = max(src_matrix[i][j], max(src_matrix[i][j+1], src_matrix[i][j+2]));
			dst_matrix[i][j] = grey;
			dst_matrix[i][j+1] = grey;
			dst_matrix[i][j+2] = grey;
			dst_matrix[i][j+3] = src_matrix[i][j+3];
		}
	}
}

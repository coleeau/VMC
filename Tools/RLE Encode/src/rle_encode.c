#include <stdio.h>
#include <stdbool.h>
#include <errno.h>

	FILE *data;
	FILE *output;
	bool done;	
	bool eof;
	unsigned char A;
	unsigned char B;
	char bitlength;
	unsigned char shift;
	unsigned char c;
	
int getbit(){
	
	if(shift == 0){
		shift = 8;
		c = fgetc(data);
		if(feof(data)){
			eof = true;
			return 0;
		}
	}
		
	
	if(shift != 8){
		c = c << 1;
	} 
	if(c > 127){
		A = 1;
	}
	else{
		A = 0;
		}
	--shift;
	//printf("%d\n", A);
	return A;
}
	


int writetofile(){
	char out;
	if(B == 1){
		out = bitlength | 128;
	}
	else{
		out = bitlength & 127;
	}
	// printf("out");
	// printf("%d\n", out);
	putc(out, output);
}



int main(){



	
	
	
	done = false;
	bitlength = 0;
	shift = 0;
	

	
	data = fopen("in.bin", "rb");
		if(errno == true){
			return (2);
		}
	output = fopen("out.bin", "wb");
		if(errno == true){
			return (3);
		}

	// start find bit
		getbit();
		B = A;
	while(done == false){
		
		

		// printf("%d\n", bitlength);
		// printf("%d\n", A);
		// printf("%d\n", B);
		if (eof == true){
			writetofile();
			done = true;
			return (0);
		}
		else if(A != B){
			writetofile();
			B = A;
			bitlength = 0;
		}
		else if (bitlength >= 127){
			writetofile();
			bitlength = 0;
		}
		++bitlength;
		getbit();
	}
	fclose(data);
	fclose(output);
	
}
	
	

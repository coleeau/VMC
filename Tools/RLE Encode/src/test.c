#include <stdio.h>


int main(){
	
	char c;
	
	FILE *fp;
	
	fp = fopen("in.pbm", "rb");
	
	
	
	while(1){
		c = fgetc(fp);
		if( feof(fp)){
			break;
		}
		printf("%c", c);
	}
	fclose(fp);
	
	return 0;
}
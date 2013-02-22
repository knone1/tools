#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>


#define REG_SIZE 32
#define BYTE 8
#define CHAR 4
#define NIBBLE 4

#define BYTES_IN_CHAR 2

#define GPIO_BASE 0xff119000
#define N_GPIOS 96

/* GPIO REGISTERS */
#define GPIO_GPLR0	0x00
#define GPIO_GPLR1	0x04
#define GPIO_GPLR2	0x08
#define GPIO_GPDR0	0x0C
#define GPIO_GPDR1	0x10
#define GPIO_GPDR2	0x14
#define GPIO_GPSR0	0x18
#define GPIO_GPSR1	0x1C
#define GPIO_GPSR2	0x20
#define GPIO_GPCR0	0x24
#define GPIO_GPCR1	0x28
#define GPIO_GPCR2	0x2C
#define GPIO_GRER0	0x30
#define GPIO_GRER1	0x34
#define GPIO_GRER2	0x38
#define GPIO_GFER0	0x3C
#define GPIO_GFER1	0x40
#define GPIO_GFER2	0x44
#define GPIO_GEDR0	0x48
#define GPIO_GEDR1	0x4C
#define GPIO_GEDR2	0x50
#define GPIO_GAFR0_L	0x54
#define GPIO_GAFR0_U	0x58
#define GPIO_GAFR1_L	0x5C
#define GPIO_GAFR1_U	0x60
#define GPIO_GAFR2_L	0x64
#define GPIO_GAFR2_U	0x68














#define MAX_SIZE 10000

#define DEBUG


#ifdef DEBUG
	#define pr_dbg(...) printf(__VA_ARGS__);
#else
	#define pr_dbg(...) {while(0)};	
#endif

/******************************************\

	Text parsing

\*******************************************/

int print_buff(unsigned char *data, int size)
{
	int i = 0;

	for (i = 0; i < size; i++)
		printf(" %02x", data[i]);		
	printf("\n");
	return 0;
}

int remove_address(char *data)
{
	int i = 0, j = 0;
	bool ignore = false;
	char data_tmp[MAX_SIZE] ;

	pr_dbg("input:\n %s\n",data);

	for (i = 0; i < MAX_SIZE; i++) {
		char p = data[i];
		if (p == '[') {
			ignore = true;
			continue;
		}
		if (p == ']') {
			ignore = false;
			continue;
		}
		if (!ignore)
			data_tmp[j++] = p;
		if (p == '\0')
			break;
	}

	strcpy(data, data_tmp);	
	pr_dbg("Output:\n%s\n",data);
	return 0;
}

int remove_space(char *data)
{
	int i = 0, j = 0;
	char data_tmp[MAX_SIZE] ;

	pr_dbg("input:\n %s\n",data);
	for (i = 0; i < MAX_SIZE; i++) {
		char p = data[i];
		if ((p == ' ') || (p == '\n') ) {
			continue;
		}
		data_tmp[j++] = p;
		if (p == '\0')
			break;
	}

	strcpy(data, data_tmp);	
	pr_dbg("Output:\n%s\n",data);
	return 0;
}

unsigned char char2hex(char data)
{
	int i = 0;
	if ('0' <= data && data <= '9') {
    		i = data - '0';
	} else if ('a' <= data && data <= 'f') {
 		i = 10 + data - 'a';
	} else if ('A' <= data && data <= 'F') {
		i = 10 + data - 'A';
	} else {
    		printf("char2hex error %c\n", data);
		return -1;
	}
	return i;
}
int reorder_bytes(unsigned char *data, int size)
{
	int i = 0;
	pr_dbg("Input:\n",data);
	print_buff(data, size);


	for (i = 0; i < size; i++) {
		unsigned char temp = data[i];
		data[i] = data[i+1];
		data[i+1] = temp;
		i++;
	}


	pr_dbg("Output:\n",data);
	print_buff(data, size);

	return 0;
}
int buff_char2hex(unsigned char *data, int *size1)
{
	int i = 0, j = 0, size = 0;
	unsigned char data_tmp[MAX_SIZE] ;

	pr_dbg("input:\n %s\n",data);
	for (i = 0; i < MAX_SIZE; i++) {
		char p = data[i];
		if (p == '\0')
			break;
		data_tmp[j++] = char2hex(p);
	}
	size = j;
	for (i = 0; i < size; i++)
		data[i] = data_tmp[i];

	pr_dbg("2 Output:\n");	
	print_buff(data, size);

	reorder_bytes(data, size);

	pr_dbg("3 Input:\n",data);
	print_buff(data, size);

	size /= 2;
	for (i = 0, j = 0; i < size ; i++ ) {
		unsigned char p = data[j++];
		unsigned char p2 = data[j++];
		p |= p2 << (NIBBLE);
		data_tmp[i] = p;
	}
	
	for (i = 0; i < size; i++)
		data[i] = data_tmp[i];

	pr_dbg("Output:\n");
	print_buff(data_tmp, size);

	return 0;
}


/******************************************\

	show funcions

\*******************************************/


bool is_bit_set(unsigned int data, unsigned int pos)
{
	if (data & (1 << pos))
		return true;
	return false;
}

int show_gpio(unsigned int add, char *data, unsigned int size)
{
	int i = 0, j = 0;	

	printf("\nGPIO Pin Level Registers:\n");
	for (j = 0; j < ((REG_SIZE / BYTE) * 2); j++)
		for (i = 0; i < (CHAR); i++) {
			printf("GPIO_%d %s ", (j * CHAR) + i,
				is_bit_set(data[(GPIO_GPLR0 * BYTES_IN_CHAR) + j], i)? "HIGH":"LOW");
			printf("GPIO_%d %s ", (j * CHAR) + i + REG_SIZE,
				is_bit_set(data[(GPIO_GPLR1 * BYTES_IN_CHAR) + j], i)? "HIGH":"LOW");
			printf("GPIO_%d %s\n", (j * CHAR) + i + (REG_SIZE * 2),
				is_bit_set(data[(GPIO_GPLR2 * BYTES_IN_CHAR)+ j], i)? "HIGH":"LOW");
		}

	printf("\nGPIO Pin Direction Register:\n");
	for (j = 0; j < ((REG_SIZE / BYTE) * BYTES_IN_CHAR); j++)
		for (i = 0; i < (CHAR); i++) {
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 0),
				is_bit_set(data[(GPIO_GPDR0 * BYTES_IN_CHAR) + j], i)? "OUT":"IN");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 1),
				is_bit_set(data[(GPIO_GPDR1 * BYTES_IN_CHAR) + j], i)? "OUT":"IN");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 2),
				is_bit_set(data[(GPIO_GPDR2 * BYTES_IN_CHAR)+ j], i)? "OUT":"IN");
			printf("\n");
		}	

	printf("\nGPIO Pin-Output Set Registers\n");
	for (j = 0; j < ((REG_SIZE / BYTE) * BYTES_IN_CHAR); j++)
		for (i = 0; i < (CHAR); i++) {
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 0),
				is_bit_set(data[(GPIO_GPSR0 * BYTES_IN_CHAR) + j], i)? "R":"R");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 1),
				is_bit_set(data[(GPIO_GPSR1 * BYTES_IN_CHAR) + j], i)? "R":"R");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 2),
				is_bit_set(data[(GPIO_GPSR2 * BYTES_IN_CHAR)+ j], i)? "R":"R");
			printf("\n");
		}	

	printf("\nGPIO Pin-Output Clear Registers\n");
	for (j = 0; j < ((REG_SIZE / BYTE) * BYTES_IN_CHAR); j++)
		for (i = 0; i < (CHAR); i++) {
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 0),
				is_bit_set(data[(GPIO_GPCR0 * BYTES_IN_CHAR) + j], i)? "R":"R");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 1),
				is_bit_set(data[(GPIO_GPCR1 * BYTES_IN_CHAR) + j], i)? "R":"R");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 2),
				is_bit_set(data[(GPIO_GPCR2 * BYTES_IN_CHAR)+ j], i)? "R":"R");
			printf("\n");
		}	

	printf("\nGPIO Rising-Edge Detect Enable Registers\n");
	printf("1 = Sets corresponding GEDR status bit when a rising edge is detected\n");
	printf("0 = Disables rising-edge detect enable.\n");
	for (j = 0; j < ((REG_SIZE / BYTE) * BYTES_IN_CHAR); j++)
		for (i = 0; i < (CHAR); i++) {
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 0),
				is_bit_set(data[(GPIO_GRER0 * BYTES_IN_CHAR) + j], i)? "ON":"OFF");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 1),
				is_bit_set(data[(GPIO_GRER1 * BYTES_IN_CHAR) + j], i)? "ON":"OFF");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 2),
				is_bit_set(data[(GPIO_GRER2 * BYTES_IN_CHAR)+ j], i)? "ON":"OFF");
			printf("\n");
		}

	printf("\nFalling-Edge Detect Enable Registers:\n");
	printf("0 = Disables rising-edge detect enable.\n");
	printf("1 = Sets corresponding GEDR status bit when a falling edge is detected on the GPIO pin.\n");
	for (j = 0; j < ((REG_SIZE / BYTE) * BYTES_IN_CHAR); j++)
		for (i = 0; i < (CHAR); i++) {
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 0),
				is_bit_set(data[(GPIO_GFER0 * BYTES_IN_CHAR) + j], i)? "ON":"OFF");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 1),
				is_bit_set(data[(GPIO_GFER1 * BYTES_IN_CHAR) + j], i)? "ON":"OFF");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 2),
				is_bit_set(data[(GPIO_GFER2 * BYTES_IN_CHAR)+ j], i)? "ON":"OFF");
			printf("\n");
		}

	printf("\nGPIO Pin Edge Detect Status:\n");
	printf("0 = No edge detect has occurred on pin as specified in GRER and/or GFER.\n");
	printf("1 = Edge detect has occurred on pin as specified in GRER and/or GFER.\n");
	for (j = 0; j < ((REG_SIZE / BYTE) * BYTES_IN_CHAR); j++)
		for (i = 0; i < (CHAR); i++) {
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 0),
				is_bit_set(data[(GPIO_GEDR0 * BYTES_IN_CHAR) + j], i)? "ON":"OFF");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 1),
				is_bit_set(data[(GPIO_GEDR1 * BYTES_IN_CHAR) + j], i)? "ON":"OFF");
			printf("GPIO_%d %s ", (j * CHAR) + i + (REG_SIZE * 2),
				is_bit_set(data[(GPIO_GEDR2 * BYTES_IN_CHAR)+ j], i)? "ON":"OFF");
			printf("\n");
		}
	
	printf("\nGPIO Alternate Function Select:\n");
	for (j = 0; j < N_GPIOS; j++) {
		int reg = 0;
		int index = j / 14;	
		unsigned int value = 0;
		unsigned int mask = 0;

		switch (index) {
		case 0:	reg = GPIO_GAFR0_L;
		case 1: reg = GPIO_GAFR0_U;
		case 2: reg = GPIO_GAFR1_L;
		case 3: reg = GPIO_GAFR1_U;
		case 4: reg = GPIO_GAFR2_L;
		case 5: reg = GPIO_GAFR2_U;
		}
		/*4 bytes 8 characters*/
		for(i = 0; i < 8; i++)
			value |= data[reg + i] << (4 * i);

		mask = 0x3 << ((j % 16) * 2);
	
		printf("GPIO_%d %x %x\n",j, value, value & mask);
	}
	


	return 0;
}


int main()
{
	
	char input[100000] = 
"[ff119000] 51 a0 00 c0 45 12 48 c6 3e c0 20 76 00 00 a7 00 10 c1 8b 0e 00 40 00 1c 00 00 00 00 00 00 00 00 \
[ff119080] 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 09 00 00 c0 0a 28 00 10 20 10 00 00 05 00 00 c0 \
[ff119100] 05 0a 00 e0 20 a1 00 40 00 00 00 00 00 00 00 00 00 00 00 00 00 55 55 1a 95 56 55 05 00 00 00 00 \
[ff119180] 00 00 00 00 00 10 a4 00 55 00 00 00 04 00 00 00 00 00 00 00 00 00 00\0" ;	
	int size = 0;

	remove_address(input);
	remove_space(input);
	buff_char2hex(input, &size);
	
//	show_gpio(GPIO_BASE, input, size);
	printf("\ndone.\n");
	return 0;
}

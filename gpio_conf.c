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
#define GPIO_GFBR0	0x6C
#define GPIO_GFBR1	0x70
#define GPIO_GFBR2	0x74
#define GPIO_GPIT0	0x78
#define GPIO_GPIT1	0x7C
#define GPIO_GPIT2	0x80
#define MAX_SIZE	100000

#define DEBUG


#ifdef DEBUG
	#define pr_dbg(...) printf("%s %d ", __FUNCTION__,__LINE__);printf(__VA_ARGS__);
#else
	#define pr_dbg(...) {while(0)};	
#endif

/******************************************\

	Input Text parsing

\*******************************************/

unsigned char ischar(char data)
{
	int i = 0;
	if ('0' <= data && data <= '9') {
    		i = data - '0';
	} else if ('a' <= data && data <= 'f') {
 		i = 10 + data - 'a';
	} else if ('A' <= data && data <= 'F') {
		i = 10 + data - 'A';
	} else if ('[' == data || data == ']') {
	} else {
		return false;
	}
	return true;
}


int print_buff(unsigned char *data, int size)
{
	int i = 0;

	for (i = 0; i < size; i++)
		printf(" %02x", data[i]);		
	printf("\n");
	return 0;
}

int p_buff_int(unsigned char *data, int size) 
{
	int i = 0;
	unsigned int *pl = (unsigned int *)data;
	for (i = 0 ; i < size/4 ; i++) {
		printf("data[%x] = 0x%08x\n",i*4,*(pl+i));	
	}
	return 0;
}


int remove_junk(char *data, int size)
{
	int i = 0, j = 0;
	bool ignore = false;
	char data_tmp[MAX_SIZE] ;

	pr_dbg("input:\n %s\n",data);

	for (i = 0; i < MAX_SIZE; i++) {
		char p = data[i];
		if (!ischar(p))
			continue;

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
int buff_char2hex(unsigned char *data, int size1)
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

	/* 2 nibbles  = 2 charecters = char = 1 byte */
	size /= 2;
	for (i = 0, j = 0; i < size ; i++ ) {
		unsigned char p = data[j++];
		unsigned char p2 = data[j++];
		p |= p2 << (NIBBLE);
		data_tmp[i] = p;
	}

	/*copy it back to the buff*/	
	for (i = 0; i < size; i++)
		data[i] = data_tmp[i];

	pr_dbg("Output:\n");
	print_buff(data_tmp, size);

	return 0;
}


/******************************************\

	Tool funcions

\*******************************************/


bool is_bit_set(unsigned int data, unsigned int pos)
{
	if (data & (1 << pos))
		return true;
	return false;
}

/******************************************\

	GPIO funcions

\*******************************************/
int show_gpio_g(int offset, unsigned char *p)
{
	int gpio = 0, j = 0, i = 0;
	unsigned int *pl = (unsigned int *) (p);	

	pl += (offset / 4);
	pr_dbg("show_gpio_g data: %08x\n", *(pl + 0));
	pr_dbg("show_gpio_g data: %08x\n", *(pl + 1));
	pr_dbg("show_gpio_g data: %08x\n", *(pl + 2));

	for (gpio = 0; gpio < N_GPIOS / 3; gpio++ ) {
		for (i = 0; i < 3; i++) {
			if (gpio == 15) {
				printf("GPIO_%d %s ",
					(gpio + (i * REG_SIZE)),
					is_bit_set(*(pl + i),
					gpio) ? "R":"R");
				continue;
			}
			printf("GPIO_%d %s ",
				(gpio + (i * REG_SIZE)),
				is_bit_set(*(pl + i),
				gpio) ? "1":"0");
		}
		printf("\n");
	}
	return 0;

}

int show_gpio_alt(int offset, unsigned char *p, int gpio_base)
{
	int gpio = 0, j = 0, i = 0;
	unsigned int *pl = (unsigned int *)(p);

	pl += (offset / 4);
	pr_dbg("show_gpio_alt data: %08x\n", *(pl + 0));

	for (gpio = 0; gpio < 15; gpio++) {
		unsigned int data = *(pl);

		/* select only interesting bits */
		data &= (0x3 << (gpio * 2));
		data = (data >> (gpio * 2));
		printf("GPIO_%d FUNC %d\n", gpio + gpio_base, data);
	}	

	return 0;
}
int gpio_dump(char *data)
{
	unsigned char *p = (unsigned char *)data;

	printf("\nGPIO Pin Level Registers:\n");
	show_gpio_g(GPIO_GPLR0, p);
	printf("\nGPIO Pin Direction Register:\n");
	show_gpio_g(GPIO_GPDR0, p);

	printf("\nGPIO Pin-Output Set Registers:\n");
	show_gpio_g(GPIO_GPSR0, p);
	printf("\nGPIO Pin-Output Clear Registers:\n");
	show_gpio_g(GPIO_GPCR0, p);
	printf("\nGPIO Rising-Edge Detect Enable Registers:\n");
	show_gpio_g(GPIO_GRER0, p);
	printf("\nGPIO Falling-Edge Detect Enable Registers:\n");
	show_gpio_g(GPIO_GFER0, p);
	printf("\nGPIO Edge Detect Status Register:\n");
	show_gpio_g(GPIO_GEDR0, p);
	printf("\nGPIO Function Registers:\n");
	show_gpio_alt(GPIO_GAFR0_L, p, 16 * 0);
	show_gpio_alt(GPIO_GAFR0_U, p, 16 * 1);
	show_gpio_alt(GPIO_GAFR1_L, p, 16 * 2);
	show_gpio_alt(GPIO_GAFR1_U, p, 16 * 3);
	show_gpio_alt(GPIO_GAFR2_L, p, 16 * 4);
	show_gpio_alt(GPIO_GAFR2_U, p, 16 * 5);
	printf("\nGPIO Glitch Filter Bypass Register:\n");
	show_gpio_g(GPIO_GFBR0, p);
	printf("\nGPIO Interrupt type Register:\n");
	show_gpio_g(GPIO_GPIT0, p);
	return 0;
}

/******************************************\

	MAIN

\*******************************************/
int main()
{
	
	char *input;
	int size = 0;
	FILE *fp;
	int i = 0;


	fp = fopen("/home/axelh/tools/axeltest.txt","w");
	fprintf(fp,"%s","r1 mmio 0xff119000 0x77");
	fclose(fp);

	fp = fopen("/home/axelh/tools/axeltest2.txt","r");
	/* find the size */	
	fseek(fp, 0L, SEEK_END);
	size = ftell(fp);
	fseek(fp, 0L, SEEK_SET);	
	input = malloc(size);
	/* read into buffer */
	while (fscanf(fp, "%c",&input[i++]) != EOF) {
		printf("%c",input[i -1]);
	}
	fclose(fp);

	remove_junk(input, size);
	buff_char2hex(input, size);
	gpio_dump(input);

	printf("\ndone.\n");
out:
	free(input);
	return 0;
}

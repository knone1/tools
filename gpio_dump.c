#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>

#ifdef DEBUG
	#define pr_dbg(...) \
		do {\
			printf("%s %d ", __FUNCTION__, __LINE__);\
			printf(__VA_ARGS__);\
		} while (0);
#else
	#define pr_dbg(...) do {} while (0);
#endif

/* GPIO REGISTERS */
#define GPIO_BASE_MDF	0xff12c000
#define GPIO_BASE_CLV	0xff119000
#define GPIO_SIZE	0x80

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

typedef struct {
	unsigned int offset;
	char *reg_name;
	char *description;
	int gpio_base;
} reg_table;

reg_table gpio_table[100] = {
{GPIO_GPLR0, "-GPIO_GPLR0", "GPIO Pin Level Registers", 0},
{GPIO_GPLR1, "-GPIO_GPLR1", "GPIO Pin Level Registers", 32},
{GPIO_GPLR2, "-GPIO_GPLR2", "GPIO Pin Level Registers", 64},
{GPIO_GPDR0, "-GPIO_GPDR0", "GPIO Pin Direction Registers", 0},
{GPIO_GPDR1, "-GPIO_GPDR1", "GPIO Pin Direction Registers", 32},
{GPIO_GPDR2, "-GPIO_GPDR2", "GPIO Pin Direction Registers", 64},
{GPIO_GPSR0, "-GPIO_GPSR0", "GPIO Pin-Output Set Registers", 0},
{GPIO_GPSR1, "-GPIO_GPSR1", "GPIO Pin-Output Set Registers", 32},
{GPIO_GPSR2, "-GPIO_GPSR2", "GPIO Pin-Output Set Registers", 64},
{GPIO_GPCR0, "-GPIO_GPCR0", "GPIO Pin-Output Clear Registers", 0},
{GPIO_GPCR1, "-GPIO_GPCR1", "GPIO Pin-Output Clear Registers", 32},
{GPIO_GPCR2, "-GPIO_GPCR2", "GPIO Pin-Output Clear Registers", 64},
{GPIO_GRER0, "-GPIO_GRER0", "GPIO Rising-Edge Detect Enable Registers", 0},
{GPIO_GRER1, "-GPIO_GRER1", "GPIO Rising-Edge Detect Enable Registers", 32},
{GPIO_GRER2, "-GPIO_GRER2", "GPIO Rising-Edge Detect Enable Registers", 64},
{GPIO_GFER0, "-GPIO_GFER0", "GPIO Falling-Edge Detect Enable Registers", 0},
{GPIO_GFER1, "-GPIO_GFER1", "GPIO Falling-Edge Detect Enable Registers", 32},
{GPIO_GFER2, "-GPIO_GFER2", "GPIO Falling-Edge Detect Enable Registers", 64},
{GPIO_GEDR0, "-GPIO_GEDR0", "GPIO Edge Detect Status Registers", 0},
{GPIO_GEDR1, "-GPIO_GEDR1", "GPIO Edge Detect Status Registers", 32},
{GPIO_GEDR2, "-GPIO_GEDR2", "GPIO Edge Detect Status Registers", 64},
{GPIO_GAFR0_L, "-GPIO_GAFR0_L", "GPIO Function Registers", 0},
{GPIO_GAFR0_U, "-GPIO_GAFR0_U", "GPIO Function Registers", 16},
{GPIO_GAFR1_L, "-GPIO_GAFR1_L", "GPIO Function Registers", 32},
{GPIO_GAFR1_U, "-GPIO_GAFR1_U", "GPIO Function Registers", 48},
{GPIO_GAFR2_L, "-GPIO_GAFR2_L", "GPIO Function Registers", 64},
{GPIO_GAFR2_U, "-GPIO_GAFR2_U", "GPIO Function Registers", 80},
{GPIO_GFBR0, "-GPIO_GFBR0", "GPIO Glitch Filter Bypass Registers", 0},
{GPIO_GFBR1, "-GPIO_GFBR1", "GPIO Glitch Filter Bypass Registers", 32},
{GPIO_GFBR2, "-GPIO_GFBR2", "GPIO Glitch Filter Bypass Registers", 64},
{GPIO_GPIT0, "-GPIO_GPIT0", "GPIO Interrupt type Registers", 0},
{GPIO_GPIT1, "-GPIO_GPIT1", "GPIO Interrupt type Registers", 32},
{GPIO_GPIT2, "-GPIO_GPIT2", "GPIO Interrupt type Registers", 64},
{0, "-GPIO_ALL", "GPIO dump all registers"},
{0, NULL, NULL},
};

#define F_DUMP_CMD "/sys/kernel/debug/dump_cmd"
#define F_DUMP_OUT "/sys/kernel/debug/dump_output"
#define REG_SIZE 32

/* program is a state machine */
#define STATE_MAIN	0x0
#define STATE_GPIO	0x1
#define STATE_EXIT	0x2
unsigned int state;

#define PLAT_MDF	0x0
#define PLAT_CLV	0x1
unsigned int platform;

int show_help(void);

/******************************************\

	helper functions

\*******************************************/
bool is_bit_set(unsigned int data, unsigned int pos)
{
	if (data & (1 << pos))
		return true;
	return false;
}

int bit_value(unsigned int data, int pos, int n)
{
	unsigned int mask = (1 << n) - 1;
	pos *= n;

	data &= (mask << pos);
	data = (data >> pos);
	return data;

}

unsigned char ischar(char data)
{
	int i = 0;

	if (data == 0x20)
		return false;

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
			printf("char2hex error %c %x\n", data, data);
		return -1;
	}
	return i;
}


int print_buff(unsigned char *data, int size)
{
	int i = 0;

	for (i = 0; i < size; i++)
		printf(" %02x", data[i]);
	printf("\n");
	return 0;
}

int print_buff_int(unsigned char *data, int size)
{
	int i = 0;
	unsigned int *pl = (unsigned int *)data;
	for (i = 0 ; i < size/4 ; i++)
		printf("data[%x] = 0x%08x\n", i*4, *(pl+i));

	return 0;
}

int remove_junk(char *data, int *size)
{
	int i = 0, j = 0;
	bool ignore = false;
	char *p1 = NULL, *p2 = NULL;

	pr_dbg("input:\n %s\n", data);

	p1 = p2 = data;
	for (i = 0; i < *size; i++, p1++) {

		if (!ischar(*p1))
			continue;

		if (*p1 == '[') {
			ignore = true;
			continue;
		}
		if (*p1 == ']') {
			ignore = false;
			continue;
		}
		if (!ignore)
			*p2++ = *p1;
	}
	*p2 = '\0';
	*size = p2 - data;
	pr_dbg("Output:\n%s\n", data);

	return 0;
}

/* swap two pointer values */
int swap(char *p1, char *p2)
{
	int i = 0;
	char tmp = *p1;
	*p1 = *p2;
	*p2 = tmp;
	return 0;
}

/* combine 2 character values to one byte */
int combine(char *pos, char *plow, char *phigh)
{
	char d = 0;

	d |= (*phigh << 4);
	d |= *plow;
	*pos = d;

	return 0;
}

int buff_char2hex(char *data, int *size)
{
	int i = 0;
	char *p1, *p2, *p3;

	pr_dbg("input:\n %s\n", data);

	/*take two characters and combine into one hex byte*/
	for (i = 0, p1 = p2 = data; i < *size; i += 2, p1 += 2, p2++) {

		p3 = p1 + 1;
		*p1 = char2hex(*p1);
		*p3 = char2hex(*p3);
		swap(p1, p3);
		combine(p2, p1, p3);

	}
	*size = p2 - data;
	return 0;
}

/******************************************\

	FILE funcions

\*******************************************/
int get_data(char **inputp, int base, int s)
{
	int size = 0;
	FILE *fp;
	int i = 0;
	char c;
	char cmd[1000];
	char *input;

	sprintf(cmd, "r1 mmio 0x%x 0x%x", base, s);
	/* send cmd to file */
	fp = fopen(F_DUMP_CMD, "w");
	fprintf(fp, "%s", cmd);
	fclose(fp);

	/* read dump output */
	fp = fopen(F_DUMP_OUT, "r");

/*why it does not work on lex?*/
#if 0
	/* find the size */
	fseek(fp, 0L, SEEK_END);
	size = ftell(fp);
	fseek(fp, 0L, SEEK_SET);
#endif

	/* use the force: read into buffer to find size*/
	for (i = 0; c != EOF; i++) {
		char prev = c;
		fscanf(fp, "%c", &c);
		if (prev == 0xa && c == 0xa)
			break;
	}
	/*go to start of file*/
	fseek(fp, 0L, SEEK_SET);
	size = i - 1 ;
	i = 0;

	input = malloc(size);
	while (i != size)
		fscanf(fp, "%c", &input[i++]);
	fclose(fp);

	/* parse output */
	remove_junk(input, &size);
	buff_char2hex(input, &size);

	*inputp = input;

	return 0;
}

/******************************************\

	GPIO funcions

\*******************************************/
int gpio_show_std(int index, unsigned char *p, int gpios_per_reg)
{
	int gpio = 0, j = 0, i = 0;
	unsigned int *pl = (unsigned int *) (p + gpio_table[index].offset);

	printf("%s\n%s: 0x%08X\n",
		gpio_table[index].description,
		gpio_table[index].reg_name, *pl);

	/* 32 gpios per register*/
	for (gpio = 0; gpio < gpios_per_reg; gpio++)
		printf("GPIO_%d %d\n",
			(gpio + gpio_table[index].gpio_base),
			bit_value(*pl, gpio, REG_SIZE / gpios_per_reg));
	return 0;
}

int gpio_show_all(unsigned char *p)
{
	int i = 0;
	unsigned int *pl = (unsigned int *)(p);

	for (i = 0; strcmp(gpio_table[i].reg_name, "-GPIO_ALL"); i++)
		printf("%s: 0x%08X\n", gpio_table[i].reg_name,
				*(pl + (gpio_table[i].offset/4)));

}

int gpio_main(int index)
{
	char *input;

	if (platform == PLAT_MDF)
		get_data(&input, GPIO_BASE_MDF, GPIO_SIZE);
	else if (platform == PLAT_CLV)
		get_data(&input, GPIO_BASE_CLV, GPIO_SIZE);

	if (!strcmp(gpio_table[index].reg_name, "-GPIO_ALL"))
		gpio_show_all(input);
	/* GAFRx registers uses 2 bits per gpio */
	else if (GPIO_GAFR0_L <= gpio_table[index].offset && gpio_table[index].offset <= GPIO_GAFR2_U)
		gpio_show_std(index, input, 16);
	else
		gpio_show_std(index, input, 32);

	free(input);
	return 0;
}


/******************************************\

	MAIN

\*******************************************/
int set_state(int new_state)
{
	state = new_state;
	return 0;
}
int set_platform(int new_platform)
{
	platform = new_platform;
	return 0;
}

int show_help(void)
{
	if (state == STATE_MAIN) {
		printf("Options are: \n %s %s %s\n",
			"-g, --gpio:	dump gpio registers\n",
			"-h, --help:	show help of option\n",
			"Example: gpio_dump --help  or gpio_dump --gpio --help\n"
			);
	} else if (state == STATE_GPIO) {
		int i = 0;
		printf("GPIO Options are:\n");
		for (i = 0; gpio_table[i].reg_name != 0; i++)
			printf("%s :	%s\n", gpio_table[i].reg_name, gpio_table[i].description);

	}
	return 0;
}

int get_cpuinfo(void)
{
	FILE *fp;
	int i = 0;
	unsigned char c[5][100];
	char input[1000];
	int model = 0;

	/* read dump output */
	fp = fopen("/proc/cpuinfo", "r");

	/* use the force: read into buffer to find size*/
	for (i = 0; i < 100; i++) {
		fscanf(fp, "%s", &c[0][0]);
		/*break when we find "model name"*/
		if (!strcmp(&c[0][0], "model")) {
			fscanf(fp, "%s", &c[0][0]);
			if (!strcmp(&c[0][0], "name")) {
				break;
			}
		}
	}

	fscanf(fp, "%s %s %s %s %s", &c[0][0], &c[1][0],
			&c[2][0], &c[3][0], &c[4][0]);
	fclose(fp);

	if (!strcmp(c[4], "Z2420")) {
		printf("Medfield platform recognized.\n");
		return PLAT_MDF;
	} else if (!strcmp(c[4], "Z2580")) {
		printf("Clovertrail platform recognized.\n");
		return PLAT_CLV;
	}
	return -1;
}

int main(int argc, char *argv[])
{
	int i = 0;
	int j = 0;
	set_state(STATE_MAIN);
	int ret = 0;

	ret = get_cpuinfo();
	if (ret < 0) {
		printf("could not recognize platform.\n exit.\n");
		return 0;
	}

	set_platform(ret);
	/* Parse Arguments */
	for (i = 1; i < argc; i++) {
		switch (state) {
		case STATE_MAIN:
			if (!strcmp(argv[i], "--gpio") || !strcmp(argv[i], "-g")) {
				set_state(STATE_GPIO);
			} else if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
				show_help();
				set_state(STATE_EXIT);
			} else {
				printf("Wrong argument arg = %s use --help \n", argv[i], state);
				set_state(STATE_EXIT);
			}
			break;
		case STATE_GPIO:
			if (!strcmp(argv[i], "--help") || !strcmp(argv[i], "-h")) {
				show_help();
				set_state(STATE_EXIT);
				break;
			}
			for (j = 0; gpio_table[j].reg_name != NULL; j++) {
				if (!strcmp(gpio_table[j].reg_name, argv[i])) {
					gpio_main(j);
					break;
				}
			}
			if (gpio_table[j].reg_name == NULL) {
				printf("Wrong argument arg = %s use --help \n", argv[i], state);
				set_state(STATE_EXIT);
			}
			break;
		case STATE_EXIT:
			break;
		}
	}

	return 0;
}

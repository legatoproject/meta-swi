#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <linux/input.h>


int main(int ac, char **av)
{
	int fd, bytes, flush;
	unsigned char buf[20];
	int gfinished;
	int i;
	char *defdev="/dev/input/event0";
	struct input_event *ev;

	gfinished = 0;
	printf("========> Testing YKEM Keypad driver <========\n");
	printf("====> Opening %s\n", defdev);
	fd = open(defdev, O_RDONLY);
	if(fd < 0){
		printf("Open failed with err %d\n", fd);
		perror("Open");
		return 1;
	}
	printf("Open succes: %d\n", fd);
	printf("KPP TEST APP: To test Please press keys on the keypad \n"
			"else press key(2,2)(SW502 key) to terminate the keypad testing.\n");        
	while(gfinished == 0) {
		memset(buf, 0, sizeof(buf));
		bytes = read(fd, buf, sizeof(struct input_event));
		if (bytes < 0) {
			printf(" read event failed with err %d \n", bytes);
			perror("READ");
			close(fd);
			return -1;
		}else {
			//	printf(" read event success with %d bytes\n", bytes);
		}

		ev = (struct input_event *)buf;

		if (ev->type == EV_PWR) {
			if ((ev->value & 0x1f1f) == 0x1b1b) {
				gfinished = 1;
				printf("key(2,2) Pressed, Keypad "\
						"testing is terminated \n");
			} else {
				/* ev->code represents old row/column status register values;
				   and ev->value represents current row/column status register values;
				 */
				printf("Before row_status = 0x%x, column_status = 0x%x\n", ev->code & 0xff, ev->code >>8);
				printf("Now  row_status = 0x%x, column_status = 0x%x\n", ev->value & 0xff, ev->value >>8);
			}
		}
	}

	printf("KPP TEST APP: ====> Closing the Keypad device ...\n"); 
	flush = close(fd);
	if(flush < 0)  {
		printf("KPP TEST APP: Close failed with err %d\n", flush);
		perror("Close");
		return -1;
	}
	printf("KPP TEST APP: Close succes: %d\n", flush);
	printf("========> Testing YKEM Keypad driver complete <========\n");
	return 0;
}


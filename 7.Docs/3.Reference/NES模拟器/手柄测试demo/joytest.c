#include <stdio.h>
#include <sys/stat.h>
#include <fcntl.h>

typedef unsigned int __u32;
typedef short __s16;
typedef unsigned char __u8;

struct js_event {
    __u32 time;     /* event timestamp in milliseconds */
    __s16 value;    /* value */
    __u8 type;      /* event type */
    __u8 number;    /* axis/button number */
};

#define JS_EVENT_BUTTON         0x01    /* button pressed/released */
#define JS_EVENT_AXIS           0x02    /* joystick moved */
#define JS_EVENT_INIT           0x80    /* initial state of device */

int main() {
    int fd = open("/dev/input/js0", O_RDONLY);
    struct js_event e;
    while(1) {
        read(fd, &e, sizeof(e));
        int type = JS_EVENT_BUTTON | JS_EVENT_INIT;
        switch(e.type) {
            case JS_EVENT_AXIS:
                printf("axis number: %d, value: %d, time: %d\n", e.number, e.value, e.time);
                break;
            case JS_EVENT_BUTTON:
                printf("btn: number: %d, value: %d, time: %d\n", e.number, e.value, e.time);
                break;
        }
    }
    close(fd);
    return 0;
}


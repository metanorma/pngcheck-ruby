#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#include "pngcheck.c"

#define EXTRA_MESSAGE_SIZE 1024

void failed_to_open(char *extra_msg, char *fname) {
    snprintf(extra_msg, EXTRA_MESSAGE_SIZE, "Failed to open %s: %s\n", fname, strerror(errno));
    extra_msg[EXTRA_MESSAGE_SIZE-1] = 0;
}

void failed_to_dup(char *extra_msg, char *fmt) {
    snprintf(extra_msg, EXTRA_MESSAGE_SIZE, fmt, strerror(errno));
    extra_msg[EXTRA_MESSAGE_SIZE-1] = 0;
}

int pngcheck_wrapped(char *fname, char *cname, char *extra_msg) {
    int rc = kCriticalError;
    int fd = -1;
    FILE* fp = fopen(fname, "rb");
    if (fp == NULL) {
        extra_msg[0] = 'A';
        failed_to_open(extra_msg, fname);
    }
    else {
        fd = open(cname, O_WRONLY);
        if (fd == -1) {
            failed_to_open(extra_msg, cname);
        }
        else {
            int stdout_copy = dup(STDOUT_FILENO);
            if (stdout_copy == -1) {
                failed_to_dup(extra_msg, "Failed to save stdout: %s\n");
            }
            else {
                if (dup2(fd, STDOUT_FILENO) == -1) {
                    failed_to_dup(extra_msg, "Failed to reassign stdout: %s\n");
                }
                else {
                    rc = pngcheck(fp, fname, 0, NULL);
                    fflush(stdout);
                }
                dup2(stdout_copy, STDOUT_FILENO);
            }
            close(fd);
        }
        fclose(fp);
    }
    return rc;
}

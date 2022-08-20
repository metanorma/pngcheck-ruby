#ifdef _WIN32
#   include <windows.h>
#   include <share.h>
#   include <io.h>
#   include <stdio.h>
#endif

#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#ifdef _WIN32
/* https://github.com/Arryboom/fmemopen_windows  */

    FILE *fmemopen(void *buf, size_t len, char *type) {
	    int fd;
	    FILE *fp;
	    char tp[MAX_PATH - 13];
	    char fn[MAX_PATH + 1];
	    int * pfd = &fd;
	    int retner = -1;
	    char tfname[] = "MemTF_";
	    if (!GetTempPathA(sizeof(tp), tp)) return NULL;
	    if (!GetTempFileNameA(tp, tfname, 0, fn)) return NULL;
	    retner = _sopen_s(pfd, fn, _O_CREAT | _O_SHORT_LIVED | _O_TEMPORARY | _O_RDWR | _O_BINARY | _O_NOINHERIT, _SH_DENYRW, _S_IREAD | _S_IWRITE);
	    if (retner != 0) return NULL;
	    if (fd == -1) return NULL;
	    fp = _fdopen(fd, "wb+");
	    if (!fp) {
		    _close(fd);
		    return NULL;
	    }
	    fwrite(buf, len, 1, fp);
	    rewind(fp);
	    return fp;
    }
#endif

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

int pngcheck_inner(FILE* fp, char *fname, char *cname, char *extra_msg) {
    int rc = kCriticalError;
    int fd = open(cname, O_WRONLY);
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
    return rc;
}

int pngcheck_file(char *fname, char *cname, char *extra_msg) {
    int rc = kCriticalError;
    extra_msg[0] = 0;
    FILE* fp = fopen(fname, "rb");
    if (fp == NULL) {
        failed_to_open(extra_msg, fname);
    }
    else {
        rc = pngcheck_inner(fp, fname, cname, extra_msg);
        fclose(fp);
    }
    return rc;
}

int pngcheck_buffer(char *data, int size, char *cname, char *extra_msg) {
    int rc = kCriticalError;
    extra_msg[0] = 0;
    char* fname = "[memory buffer]";
    FILE* fp = fmemopen(data, size, "rb");
    if (fp == NULL) {
        failed_to_open(extra_msg, fname);
    }
    else {
        rc = pngcheck_inner(fp, fname, cname, extra_msg);
        fclose(fp);
    }
    return rc;
}

#import <dlfcn.h>
#import <stdio.h>
#import <string.h>
#import <sys/stat.h>
#import <sys/types.h>
#import <sysexits.h>
#import <unistd.h>

#define PROC_PIDPATHINFO_MAXSIZE (2048)
int proc_pidpath(pid_t pid, void *buffer, uint32_t buffersize);

/* Set platform binary flag */
#define FLAG_PLATFORMIZE (1 << 1)

void patch_setuidandplatformize(void) {
	void *handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
	if (!handle)
		return;

	dlerror();

	typedef void (*fix_setuid_prt_t)(pid_t pid);
	fix_setuid_prt_t setuidptr =
		(fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");

	typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
	fix_entitle_prt_t entitleptr =
		(fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");

	setuidptr(getpid());

	setuid(0);

	const char *dlsym_error = dlerror();
	if (dlsym_error) {
		return;
	}

	entitleptr(getpid(), FLAG_PLATFORMIZE);
}

int main(int argc, char *argv[]) {

    // sandboxed app won't be able to fork
    // and unsandboxed hacker won't really use us right?
    
//	const char *privilegedPrefix = "/Applications/";
//
//	pid_t parentPID = getppid();
//	char parentPath[PROC_PIDPATHINFO_MAXSIZE] = {0};
//	int status = proc_pidpath(parentPID, parentPath, sizeof(parentPath));
//	if (status <= 0) {
//		fprintf(stderr, "Permission denied: missing parent info\n");
//		return EX_NOPERM;
//	}
//
//	// check if parentPath start with validatedPrefix
//	if (strncmp(parentPath, privilegedPrefix, strlen(privilegedPrefix)) != 0) {
//		fprintf(stderr,
//		        "Permission denied: parent outside the privileged prefix [%s]\n",
//		        privilegedPrefix);
//		return EX_NOPERM;
//	}

	patch_setuidandplatformize();

	setuid(0);
	setgid(0);

	if (getuid() != 0) {
		fprintf(stderr, "Permission denied: failed to call setuid/setgid\n");
		return EX_NOPERM;
	}

	if (argc < 2) {
		fprintf(stderr, "Failed to load arguments, argc: %d\n", argc);
		return 0;
	}

	if (strcmp(argv[1], "whoami") == 0) {
		printf("root\n");
		return 0;
	}
	
	execv(argv[1], &argv[1]);

	return EX_UNAVAILABLE;
}

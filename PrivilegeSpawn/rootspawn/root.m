//
//  root.c
//  rootspawn
//
//  Created by Lakr Aream on 2021/12/15.
//

#import <Foundation/Foundation.h>

#import <dlfcn.h>
#import <sysexits.h>

#include "root.h"

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

void root_me(void) {
    patch_setuidandplatformize();
    
    setuid(0);
    setgid(0);
    
    if (getuid() != 0) {
        fprintf(stderr, "Permission denied: failed to call setuid/setgid\n");
        exit(EX_NOPERM);
    }
}

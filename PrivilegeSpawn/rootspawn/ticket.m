//
//  ticket.m
//  rootspawn
//
//  Created by Lakr Aream on 2021/12/15.
//

#import <Foundation/Foundation.h>

#import <sys/stat.h>
#import <sysexits.h>

#import "ticket.h"
#include "root.h"

#define PROC_PIDPATHINFO_MAXSIZE (2048)
int proc_pidpath(pid_t pid, void *buffer, uint32_t buffersize);

void ticket_file_permission_check(mode_t mode) {
    
    // if the loop breaks, with error we exit!
    do {
        if (mode & S_IXUSR) // owner execute
            break;
        if (mode & S_IRGRP) // group read
            break;
        if (mode & S_IWGRP) // group write
            break;
        if (mode & S_IXGRP) // group execute
            break;
        if (mode & S_IROTH) // other read
            break;
        if (mode & S_IWOTH) // other write
            break;
        if (mode & S_IXOTH) // other execute
            break;
        return;
    } while (false);
    
    fprintf(stderr,
            "Permission denied: ticket file has wrong permission (mode: %07o)\n",
            mode);
    exit(EX_NOPERM);
}

bool pidpath_check_passed(void) {
    // let's check if the user have permission to do so
    const char *privilegedPrefix = "/Applications/";
    pid_t parentPID = getppid();
    char parentPath[PROC_PIDPATHINFO_MAXSIZE] = {0};
    int status = proc_pidpath(parentPID, parentPath, sizeof(parentPath));
    if (status <= 0) {
        fprintf(stderr, "Permission denied: missing parent info\n");
        return false;
    }
    
    // check if parentPath start with validatedPrefix
    if (strncmp(parentPath, privilegedPrefix, strlen(privilegedPrefix)) != 0) {
        fprintf(stderr,
                "Permission denied: parent outside the privileged prefix [%s]\n",
                privilegedPrefix);
        return false;
    }
    
    return true;
}

void privileged_session_create(char *ticket_location) {
    
    if (!pidpath_check_passed()) {
        exit(EX_NOPERM);
    }
    
    // get the ticket location from argv[2]
    NSString *ticketPath = [NSString stringWithUTF8String:ticket_location];
    
    // now genereate a ticket with ticket:// and ends with aa55
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *ticket = [NSString stringWithFormat:@"ticket://%@-AA55", uuid];
    
    // let us be the root
    root_me();
    
    // now because we are root, we need to be extremely careful
    // if the ticket path length is less then 2, which means somthing wrong must
    // happen
    if (ticketPath.length < 2) {
        fprintf(stderr, "Permission denied: ticket path is too short\n");
        exit(EX_NOPERM);
    }
    
    // check if file already exists at location
    struct stat st;
    if (stat(ticket_location, &st) == 0) {
        // session file already exists
        // !!!safety belt!!!
        // check if the file is regular file not directory
        if (!S_ISREG(st.st_mode)) {
            fprintf(stderr, "Permission denied: ticket path is not a regular file\n");
            exit(EX_NOPERM);
        }
        if (S_ISDIR(st.st_mode)) {
            fprintf(stderr, "Permission denied: ticket path is a directory\n");
            exit(EX_NOPERM);
        }
        // remove it
        unlink(ticket_location);
    }
    
    // create a file with permission that only us can read and write
    int f = open(ticket_location, O_CREAT | O_RDWR, 0600);
    if (f < 0) {
        fprintf(stderr, "Permission denied: failed to create session file\n");
        exit(EX_NOPERM);
    }
    
    // chown root:wheel on this file
    chown(ticket_location, 0, 0);
    
    // write to it
    write(f, [ticket UTF8String], [ticket length]);
    
    // close the file
    close(f);
    
    // print the session ticket
    printf("%s", [ticket UTF8String]);
    
    // now we can exit
    exit(EX_OK);
}

// ticket file permission check

void session_check(char *ticket_location, char *ticket) {
    
    // if pidpath check passed, ignore session ticket check
    if (pidpath_check_passed()) {
        return;
    }
    
    // first, check if any env param is empty
    if (ticket_location == NULL || ticket == NULL) {
        fprintf(stderr, "Permission denied: missing ticket location or ticket\n");
        exit(EX_NOPERM);
    }
    
    // and if the string is empty
    if (strlen(ticket_location) == 0 || strlen(ticket) == 0) {
        fprintf(stderr, "Permission denied: missing ticket location or ticket\n");
        exit(EX_NOPERM);
    }
    
    // now let's check if the ticket file is owned by root and has the right
    // permission 0600
    struct stat st;
    if (stat(ticket_location, &st) != 0) {
        fprintf(stderr, "Permission denied: ticket file not found\n");
        exit(EX_NOPERM);
    }
    
    if (st.st_uid != 0) {
        fprintf(stderr,
                "Permission denied: ticket file has wrong permission (uid)\n");
        exit(EX_NOPERM);
    }
    
    if (st.st_gid != 0) {
        fprintf(stderr,
                "Permission denied: ticket file has wrong permission (gid)\n");
        exit(EX_NOPERM);
    }
    
    // mode check, requires 0600
    ticket_file_permission_check(st.st_mode);
    
    // now let's check if the ticket is valid
    NSString *ticketPath = [NSString stringWithUTF8String:ticket_location];
    NSString *ticketStringRead =
    [NSString stringWithContentsOfFile:ticketPath
                              encoding:NSUTF8StringEncoding
                                 error:nil];
    
    // trim the ticketStringRead with whitespace and newline
    NSString *ticketString = [ticketStringRead
                              stringByTrimmingCharactersInSet:[NSCharacterSet
                                                               whitespaceAndNewlineCharacterSet]];
    if (ticketString == nil) {
        fprintf(stderr, "Permission denied: ticket file is empty\n");
        exit(EX_NOPERM);
    }
    
    
    NSString *ticketPrefix = @"ticket://";
    if (![ticketString hasPrefix:ticketPrefix]) {
        fprintf(stderr,
                "Permission denied: ticket file does not contain a valid ticket\n");
        exit(EX_NOPERM);
    }
    
    // now, compare the ticket with param
    NSString *ticketParam = [NSString stringWithUTF8String:ticket];
    if (![ticketString isEqualToString:ticketParam]) {
        fprintf(
                stderr,
                "Permission denied: ticket file does not contain the right ticket\n");
        exit(EX_NOPERM);
    }
    
    return;
}

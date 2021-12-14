#import <Foundation/Foundation.h>

#import <sysexits.h>

#include "root.h"
#include "ticket.h"

int main(int argc, char *argv[]) {
    
    if (strcmp(argv[1], "ipc.create.root.session") == 0) {
        privileged_session_create(argv[2]);
        return EX_UNAVAILABLE;
    }
    
    // now let's check the session
    // from environment
    // - chromaticAuxiliaryExecTicket returns the ticket
    // - chromaticAuxiliaryExecTicketStore returns the ticket location
    char *ticket = getenv("chromaticAuxiliaryExecTicket");
    char *ticket_location = getenv("chromaticAuxiliaryExecTicketStore");
    session_check(ticket_location, ticket);
    // check passed, we are going to call the binary
    // but don't let them to steal our ticket
    // let's remove the env
    unsetenv("chromaticAuxiliaryExecTicket");
    unsetenv("chromaticAuxiliaryExecTicketStore");
    // qaq don't steal my ticket pls!
    
    root_me();
    
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

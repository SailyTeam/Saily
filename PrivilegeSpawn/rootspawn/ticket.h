//
//  ticket.h
//  rootspawn
//
//  Created by Lakr Aream on 2021/12/15.
//

#ifndef ticket_h
#define ticket_h

void privileged_session_create(char *ticket_location);
void session_check(char *ticket_location, char *ticket);

#endif /* ticket_h */

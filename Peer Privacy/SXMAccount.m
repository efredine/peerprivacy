//
//  SXMAccount.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMAccount.h"
#import "SXMConversation.h"


@implementation SXMAccount

@dynamic name;
@dynamic userId;
@dynamic password;
@dynamic rememberPassword;
@dynamic enabled;
@dynamic configured;
@dynamic accountType;
@dynamic conversations;

+ (SXMAccount *)deleteAndReallocate: (SXMAccount *)oldAccount inManagedObjectContext: (NSManagedObjectContext *)context
{
    SXMAccount *newAccount = [NSEntityDescription 
                           insertNewObjectForEntityForName:@"SXMAccount" 
                           inManagedObjectContext:context];
    
    newAccount.name = oldAccount.name;
    newAccount.accountType = oldAccount.accountType;
    newAccount.configured = NO;
    newAccount.enabled = YES;
    newAccount.rememberPassword = YES;
    
    [context deleteObject:oldAccount];
    
    return newAccount;
}


@end

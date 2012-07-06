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
@dynamic streamBareJidStr;

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

+ (SXMAccount *)accountForStreamBareJidStr: (NSString *)streamBareJidStr inManagedObjectContext: (NSManagedObjectContext *)context
{
    SXMAccount *account = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"SXMAccount"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"streamBareJidStr == %@", streamBareJidStr];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:fetchRequest error:&error];
    if (array == nil) {
        // deal with the error!
    }
    else if ([array count] > 0) {
        account = [array objectAtIndex:0];
    }
    
    return account;
}

+ (NSArray *)activeAccountsInManagedContext: (NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"SXMAccount"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"configured == YES"];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:fetchRequest error:&error];
    if (array == nil) {
        // deal with the error!
    }
    return array;
}

+ (NSUInteger)numberOfActiveAccountsInManagedContext: (NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"SXMAccount"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"configured == YES"];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetchRequest error:&error];
    if (count == NSNotFound)
    {
        // deal with the error
    }
    return count;
}

@end

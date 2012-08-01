//
//  SXMConversation.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-29.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMConversation.h"
#import "SXMMessage.h"
#import "XMPPMessage.h"
#import "SXMRosterCoreDataStorage.h"
#import "SXMStreamCoordinator.h"
#import "SXMAccount.h"


@implementation SXMConversation

@dynamic creationTimestamp;
@dynamic jidStr;
@dynamic lastUpdatedTimestamp;
@dynamic streamBareJidStr;
@dynamic numUnread;
@dynamic messages;
@dynamic account;

+ (SXMConversation *)conversationForJidStr: (NSString *)jidStr andStreamBareJidStr: (NSString *)streamBareJidStr inManagedObjectContext: (NSManagedObjectContext*) context
{
    NSEntityDescription *conversationEntityDescription = [NSEntityDescription entityForName:@"SXMConversation" inManagedObjectContext:context];
    NSFetchRequest *conversationRequest = [[NSFetchRequest alloc] init];
    [conversationRequest setEntity:conversationEntityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(jidStr == %@) AND (streamBareJidStr== %@)", jidStr, streamBareJidStr];
    [conversationRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:conversationRequest error:&error];
    if (array != nil && [array count] > 0)
    {
        return [array objectAtIndex:0];
    }
    else 
    {
        return nil;
    }
}

+ (SXMConversation *)conversationForUser: (XMPPUserCoreDataStorageObject *) user inManagedObjectContext: (NSManagedObjectContext *) context
{
    return [SXMConversation conversationForJidStr:user.jidStr andStreamBareJidStr:user.streamBareJidStr inManagedObjectContext:context];
}

+ (SXMConversation *)insertNewConversationForJidStr:(NSString *)jidStr andStreamBareJidStr: (NSString *)streamBareJidStr inManagedObjectContext: (NSManagedObjectContext*) context
{
    
    SXMConversation *newConversation = [NSEntityDescription
                                        insertNewObjectForEntityForName:@"SXMConversation"
                                        inManagedObjectContext:context];
    
    NSDate *now = [NSDate date];
    newConversation.creationTimestamp = now;
    newConversation.lastUpdatedTimestamp = now;
    newConversation.streamBareJidStr = streamBareJidStr;
    newConversation.jidStr = jidStr;
    newConversation.numUnread = [NSNumber numberWithInt:0];
 
    SXMAccount *account = [SXMAccount accountForStreamBareJidStr:streamBareJidStr inManagedObjectContext:context];
    newConversation.account = account;
    [account addConversationsObject:newConversation];
    
    return newConversation;
}

+ (SXMConversation *)insertNewConversationForUser: (XMPPUserCoreDataStorageObject *)user inManagedObjectContext: (NSManagedObjectContext *) context
{
    
    return [SXMConversation insertNewConversationForJidStr:user.jidStr andStreamBareJidStr:user.streamBareJidStr inManagedObjectContext:context];
}


- (SXMMessage *)insertNewMessageInManagedObjectContext: (NSManagedObjectContext *) context
{
    SXMMessage *newMessage = [NSEntityDescription
                              insertNewObjectForEntityForName:@"SXMMessage"
                              inManagedObjectContext:context];
    
    [self addMessagesObject:newMessage];
    NSDate *now = [NSDate date];
    newMessage.localTimestamp = now;
    self.lastUpdatedTimestamp = now;
    
    return newMessage;
}


- (XMPPUserCoreDataStorageObject *) user
{
    XMPPUserCoreDataStorageObject *user = nil;
    NSManagedObjectContext *moc = [[SXMRosterCoreDataStorage sharedInstance] mainThreadManagedObjectContext];
    
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:moc];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"(jidStr == %@) AND (streamBareJidStr == %@)", 
                              self.jidStr, 
                              self.streamBareJidStr];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    if (array != nil && [array count] > 0)
    {
        user = [array objectAtIndex:0];
    }
    return user;
}

- (SXMStreamManager *) streamManager
{
    SXMStreamCoordinator *streamCoordinator = [SXMStreamCoordinator sharedInstance];
    return [streamCoordinator streamManagerforStreamBareJidStr:self.streamBareJidStr];
}

@end

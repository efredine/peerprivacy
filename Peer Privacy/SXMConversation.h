//
//  SXMConversation.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-29.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "XMPPUserCoreDataStorageObject.h"
#import "SXMStreamManager.h"

@class SXMMessage;

@interface SXMConversation : NSManagedObject

@property (nonatomic, retain) NSDate * creationTimestamp;
@property (nonatomic, retain) NSString * jidStr;
@property (nonatomic, retain) NSDate * lastUpdatedTimestamp;
@property (nonatomic, retain) NSString * streamBareJidStr;
@property (nonatomic, retain) NSNumber * numUnread;
@property (nonatomic, retain) NSSet *messages;
@property (nonatomic, readonly) XMPPUserCoreDataStorageObject *user;
@property (nonatomic, readonly) SXMStreamManager *streamManager;

+ (SXMConversation *)conversationForJidStr: (NSString *)jidStr andStreamBareJidStr: (NSString *)streamBareJidStr inManagedObjectContext: (NSManagedObjectContext*) context;

+ (SXMConversation *)conversationForUser: (XMPPUserCoreDataStorageObject *) user inManagedObjectContext: (NSManagedObjectContext *) context;

+ (SXMConversation *)insertNewConversationForJidStr:(NSString *)jidStr andStreamBareJidStr: (NSString *)streamBareJidStr inManagedObjectContext: (NSManagedObjectContext*) context;

+ (SXMConversation *)insertNewConversationForUser: (XMPPUserCoreDataStorageObject *)user inManagedObjectContext: (NSManagedObjectContext *) context;

- (SXMMessage *)insertNewMessageInManagedObjectContext: (NSManagedObjectContext *) context;


@end

@interface SXMConversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(SXMMessage *)value;
- (void)removeMessagesObject:(SXMMessage *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end

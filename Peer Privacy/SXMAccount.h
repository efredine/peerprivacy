//
//  SXMAccount.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kFacebookAccountType 1
#define kGoogleAccountType 2

@class SXMConversation;

@interface SXMAccount : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * userId;
@property (nonatomic, retain) NSString * password;
@property (nonatomic) BOOL rememberPassword;
@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL configured;
@property (nonatomic) int16_t accountType;
@property (nonatomic, retain) NSSet *conversations;
@end

@interface SXMAccount (CoreDataGeneratedAccessors)

- (void)addConversationsObject:(SXMConversation *)value;
- (void)removeConversationsObject:(SXMConversation *)value;
- (void)addConversations:(NSSet *)values;
- (void)removeConversations:(NSSet *)values;

@end

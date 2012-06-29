//
//  SXMMessage.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-29.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SXMConversation;

@interface SXMMessage : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSNumber * fromMe;
@property (nonatomic, retain) NSDate * localTimestamp;
@property (nonatomic, retain) NSNumber * read;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) SXMConversation *conversation;

@end

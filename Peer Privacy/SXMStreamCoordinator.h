//
//  SXMMultiStreamManager.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SXMStreamManager.h"
#import "SXMAccount.h"

#define kFaceBookEnabled @"faceBookEnabled"
#define kGoogleEnabled @"gmailEnabled"
#define kGmailAddress @"gmailAddress"
#define kGmailPassword @"gmailPassword"
#define kFacebookStreamName @"facebook"
#define kGoogleStreamName @"google"

@interface SXMStreamCoordinator : NSObject

@property (nonatomic, strong) NSMutableArray *managedStreams;

+ (SXMStreamCoordinator *) sharedInstance;
- (void) configureStreams;
- (SXMStreamManager *)allocateStreamManagerforAccount: (SXMAccount *)account;
- (SXMStreamManager *) streamManagerForObjectPassingTest: (BOOL (^)(SXMStreamManager *obj, NSUInteger idx, BOOL *stop))predicate;
- (SXMStreamManager *) streamManagerforAccount: (SXMAccount *)account;
- (SXMStreamManager *) streamManagerforStreamBareJidStr:(NSString *)streamBareJidStr;
- (SXMStreamManager *) streamManagerforAccountType: (NSUInteger) accountType;

@end

//
//  SXMMultiStreamManager.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SXMStreamManager.h"

#define kFaceBookEnabled @"faceBookEnabled"
#define kGoogleEnabled @"gmailEnabled"
#define kGmailAddress @"gmailAddress"
#define kGmailPassword @"gmailPassword"
#define kFacebookStreamName @"facebook"
#define kGoogleStreamName @"google"

@interface SXMMultiStreamManager : NSObject

@property (nonatomic, strong) NSMutableDictionary *configuredStreams;

- (SXMStreamManager *) streamManagerforName: (NSString *)streamName;

@end

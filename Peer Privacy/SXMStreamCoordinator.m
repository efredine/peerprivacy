//
//  SXMMultiStreamManager.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMStreamCoordinator.h"
#import "SXMFacebookStreamManager.h"
#import "SXMJabberStreamManager.h"

@implementation SXMStreamCoordinator

@synthesize streamDictionary;

static SXMStreamCoordinator *sharedInstance = nil;

+ (SXMStreamCoordinator *) sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[SXMStreamCoordinator alloc] init];
    }
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        streamDictionary = [[NSMutableDictionary alloc] init];
        [self configureStreams];
    }
    return (self);
}

- (void) configureStreams {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (nil == [streamDictionary valueForKey: kFacebookStreamName] ) {
        if ( [defaults boolForKey:kFaceBookEnabled] ) {
            SXMFacebookStreamManager *faceBookStreamManager = [[SXMFacebookStreamManager alloc] init];
            [faceBookStreamManager connect];
            [streamDictionary setValue:faceBookStreamManager forKey:kFacebookStreamName];
        }
    }
    
    if (nil == [streamDictionary valueForKey: kGoogleStreamName] ) {
        if ( [defaults boolForKey:kGoogleEnabled] ) {
            NSString *theJID = [defaults stringForKey:kGmailAddress];
            NSString *thePassword = [defaults stringForKey:kGmailPassword];
            SXMJabberStreamManager *googleStreamManager = [[SXMJabberStreamManager alloc] initWithJID:theJID andPassword:thePassword ];
            [googleStreamManager connect];
            [streamDictionary setValue:googleStreamManager forKey:kGoogleStreamName];
        }
    }
}

- (SXMStreamManager *) streamManagerforName: (NSString *)streamName
{
    return [streamDictionary objectForKey:streamName];
}

- (SXMStreamManager *) streamManagerforStreamBareJidStr:(NSString *)streamBareJidStr
{
    for (SXMStreamManager *aStreamManager in [self.streamDictionary allValues] ) {
        if ([aStreamManager.xmppStream.myJID.bare isEqualToString:streamBareJidStr]) {
            return aStreamManager;
        }
    }
    return nil;
}

@end

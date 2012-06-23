//
//  SXMMultiStreamManager.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMMultiStreamManager.h"
#import "SXMFacebookStreamManager.h"
#import "SXMJabberStreamManager.h"

@implementation SXMMultiStreamManager

@synthesize configuredStreams;

- (id)init {
    if (self = [super init]) {
        configuredStreams = [[NSMutableDictionary alloc] init];
        [self configureStreams];
    }
    return (self);
}

- (void) configureStreams {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (nil == [configuredStreams valueForKey: kFacebookStreamName] ) {
        if ( [defaults boolForKey:kFaceBookEnabled] ) {
            SXMFacebookStreamManager *faceBookStreamManager = [[SXMFacebookStreamManager alloc] init];
            [faceBookStreamManager connect];
            [configuredStreams setValue:faceBookStreamManager forKey:kFacebookStreamName];
        }
    }
    
    if (nil == [configuredStreams valueForKey: kGoogleStreamName] ) {
        if ( [defaults boolForKey:kGoogleEnabled] ) {
            NSString *theJID = [defaults stringForKey:kGmailAddress];
            NSString *thePassword = [defaults stringForKey:kGmailPassword];
            SXMJabberStreamManager *googleStreamManager = [[SXMJabberStreamManager alloc] initWithJID:theJID andPassword:thePassword ];
            [googleStreamManager connect];
            [configuredStreams setValue:googleStreamManager forKey:kGoogleStreamName];
        }
    }
}

- (SXMStreamManager *) streamManagerforName: (NSString *)streamName
{
    return [configuredStreams objectForKey:streamName];
}

- (SXMStreamManager *) streamManagerforStreamBareJidStr:(NSString *)streamBareJidStr
{
    for (SXMStreamManager *aStreamManager in [self.configuredStreams allValues] ) {
        if ([aStreamManager.xmppStream.myJID.bare isEqualToString:streamBareJidStr]) {
            return aStreamManager;
        }
    }
    return nil;
}

@end

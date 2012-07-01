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

#pragma mark initialization

- (id)init {
    if (self = [super init]) {
        streamDictionary = [[NSMutableDictionary alloc] init];
        [self configureStreams];
        [self initailizeNotifications];
     }
    return (self);
}

#pragma configuration

- (void) configureStreams {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (nil == [streamDictionary valueForKey: kFacebookStreamName] ) {
        if ( [defaults boolForKey:kFaceBookEnabled] ) {
            SXMFacebookStreamManager *faceBookStreamManager = [[SXMFacebookStreamManager alloc] init];
            [faceBookStreamManager connect];
            [streamDictionary setObject:faceBookStreamManager forKey:kFacebookStreamName];
        }
    }
    else if (![defaults boolForKey:kFaceBookEnabled]){
        [streamDictionary removeObjectForKey:kFacebookStreamName];
    }
    
    if (nil == [streamDictionary valueForKey: kGoogleStreamName] ) {
        if ( [defaults boolForKey:kGoogleEnabled] ) {
            NSString *theJID = [defaults stringForKey:kGmailAddress];
            NSString *thePassword = [defaults stringForKey:kGmailPassword];
            SXMJabberStreamManager *googleStreamManager = [[SXMJabberStreamManager alloc] initWithJID:theJID andPassword:thePassword ];
            [googleStreamManager connect];
            [streamDictionary setObject:googleStreamManager forKey:kGoogleStreamName];
        }
    }
    else if (![defaults boolForKey:kGoogleEnabled]){
        [streamDictionary removeObjectForKey:kGoogleStreamName];
    }

}

#pragma mark Retrieve streams

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

#pragma mark Foreground Notifications

- (void)initailizeNotifications
{
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:app];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification 
{
    [self configureStreams];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end

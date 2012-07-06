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
    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if (nil == [streamDictionary valueForKey: kFacebookStreamName] ) {
//        
//    }
//    else if (![defaults boolForKey:kFaceBookEnabled]){
//        [streamDictionary removeObjectForKey:kFacebookStreamName];
//    }
//    
//    if (nil == [streamDictionary valueForKey: kGoogleStreamName] ) {
//        if ( [defaults boolForKey:kGoogleEnabled] ) {
//            NSString *theJID = [defaults stringForKey:kGmailAddress];
//            NSString *thePassword = [defaults stringForKey:kGmailPassword];
//            SXMJabberStreamManager *googleStreamManager = [[SXMJabberStreamManager alloc] initWithJID:theJID andPassword:thePassword ];
//            [googleStreamManager connect];
//            [streamDictionary setObject:googleStreamManager forKey:kGoogleStreamName];
//            googleStreamManager.name = @"Google";
//        }
//    }
//    else if (![defaults boolForKey:kGoogleEnabled]){
//        [streamDictionary removeObjectForKey:kGoogleStreamName];
//    }

}

#pragma mark Allocate a stream

- (SXMStreamManager *)allocateStreamManagerforAccount: (SXMAccount *)account
{
    if (account.accountType == kFacebookAccountType) 
    {
        SXMFacebookStreamManager *faceBookStreamManager = [[SXMFacebookStreamManager alloc] init];
        [streamDictionary setObject:faceBookStreamManager forKey:kFacebookStreamName];
        faceBookStreamManager.account = account;
        return faceBookStreamManager;
    }
    else if (account.accountType == kGoogleAccountType)
    {
        NSString *theJID = account.userId;
        NSString *thePassword = account.password;
        SXMJabberStreamManager *googleStreamManager = [[SXMJabberStreamManager alloc] initWithJID:theJID andPassword:thePassword ];
        [streamDictionary setObject:googleStreamManager forKey:kGoogleStreamName];
        googleStreamManager.account = account;
        return googleStreamManager;
    }
    return nil;
}

#pragma mark Retrieve streams

- (SXMStreamManager *) streamManagerforName: (NSString *)streamName
{
    return [streamDictionary objectForKey:streamName];
}

- (SXMStreamManager *) streamManagerforStreamBareJidStr:(NSString *)streamBareJidStr
{
    NSLog(@"streamManager for %@", streamBareJidStr);
    for (SXMStreamManager *aStreamManager in [self.streamDictionary allValues] ) {
        NSLog(@"Testing %@", aStreamManager.xmppStream.myJID.bare);
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

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
#import "SXMAppDelegate.h"

@implementation SXMStreamCoordinator

@synthesize managedStreams;

static SXMStreamCoordinator *sharedInstance = nil;

+ (SXMStreamCoordinator *) sharedInstance
{
    if (sharedInstance == nil) {
        sharedInstance = [[SXMStreamCoordinator alloc] init];
    }
    return sharedInstance;
}


- (SXMAppDelegate *)appDelegate
{
	return (SXMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark initialization

- (id)init {
    if (self = [super init]) {
        self.managedStreams = [[NSMutableArray alloc] init];
        [self configureStreams];
        [self initailizeNotifications];
     }
    return (self);
}

#pragma configuration

- (void) configureStreams {
    NSArray *activeAccounts = [SXMAccount activeAccountsInManagedContext:[self appDelegate].managedObjectContext];
    for (SXMAccount *account in activeAccounts) {
        SXMStreamManager *aStreamManager = [self allocateStreamManagerforAccount:account];
        [aStreamManager connect];
    }
}

#pragma mark Allocate a stream

- (SXMStreamManager *)allocateStreamManagerforAccount: (SXMAccount *)account
{
    SXMStreamManager *streamManager = [self streamManagerforAccount:account];
    if (streamManager != nil) 
    {
        return streamManager;
    }
    if (account.accountType == kFacebookAccountType) 
    {
        streamManager = [[SXMFacebookStreamManager alloc] init];
    }
    else if (account.accountType == kGoogleAccountType)
    {
        NSString *theJID = account.userId;
        NSString *thePassword = account.password;
        streamManager = [[SXMJabberStreamManager alloc] initWithJID:theJID andPassword:thePassword ];
    }
    if (nil != streamManager) 
    {
        streamManager.account = account;
        streamManager.streamCoordinator = self;
        [managedStreams addObject:streamManager];
    }
    return streamManager;
}

#pragma mark Retrieve streams

- (SXMStreamManager *) streamManagerForObjectPassingTest: (BOOL (^)(SXMStreamManager *obj, NSUInteger idx, BOOL *stop))predicate
{
    SXMStreamManager *result = nil;
    NSUInteger index = [managedStreams indexOfObjectPassingTest:predicate];    
    if (index != NSNotFound) 
    {
        result = [managedStreams objectAtIndex:index];
    }
    return result;   
}

- (SXMStreamManager *) streamManagerforAccount: (SXMAccount *)account
{
    return [self streamManagerForObjectPassingTest:^BOOL(SXMStreamManager *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.account isEqual:account]) 
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
 }

- (SXMStreamManager *) streamManagerforStreamBareJidStr:(NSString *)streamBareJidStr
{
    return [self streamManagerForObjectPassingTest:^BOOL(SXMStreamManager *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.xmppStream.myJID.bare isEqualToString:streamBareJidStr]) 
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
}

- (SXMStreamManager *) streamManagerforAccountType: (NSUInteger) accountType
{
    return [self streamManagerForObjectPassingTest:^BOOL(SXMStreamManager *obj, NSUInteger idx, BOOL *stop) {
        if (obj.account.accountType == accountType) 
        {
            *stop = YES;
            return YES;
        }
        return NO;
    }];    
}

- (void) removeStreamManager:(SXMStreamManager *)streamManager
{
    [self.managedStreams removeObject:streamManager];
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

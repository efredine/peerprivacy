//
//  SXMFacebookStreamManager.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMFacebookStreamManager.h"
#import "XMPP.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

// For TESTING purposes this project uses the XMPPFacebook FBTest Facebook app.
// You MUST replace this with your own appID if you're going to be
// integrating Facebook XMPP into your own application.
#define FACEBOOK_APP_ID @"124242144347927"


// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@implementation SXMFacebookStreamManager

@synthesize facebook;

- (XMPPStream *)allocateStream
{
    DDLogVerbose(@"initializing stream for Facebook");
    return [[XMPPStream alloc] initWithFacebookAppId:FACEBOOK_APP_ID];
}

-(BOOL)connect
{
    DDLogVerbose(@"Facebook connect");
    facebook = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID andDelegate:self];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) {
        DDLogVerbose(@"Using existing FB token");
        facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
    
    if (![facebook isSessionValid]) {
        // TODO extend access token
        DDLogVerbose(@"FB session is invalid - re-authorizing");        
        [facebook authorize:[NSArray arrayWithObject:@"xmpp_login"]];    
    }    
    else 
    {
        DDLogVerbose(@"Facebook session is valid - open xmpp session");
        NSError *error = nil;
        if (![self.xmppStream connect:&error])
        {
            DDLogError(@"%@: Error in xmpp connection: %@", THIS_FILE, error);
        }
        DDLogVerbose(@"myJID = %@", [self.xmppStream.myJID full]);
    }
    
    NSLog(@"Returning from connect request");
    return YES;
    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    if (![self.xmppStream isSecure])
    {
        DDLogVerbose(@"XMPP STARTTLS...");
        NSError *error = nil;
        BOOL result = [self.xmppStream secureConnection:&error];
        
        if (result == NO)
        {
            DDLogError(@"%@: Error in xmpp STARTTLS: %@", THIS_FILE, error);
        }
    } 
    else 
    {
        DDLogVerbose(@"XMPP X-FACEBOOK-PLATFORM SASL...");
        NSError *error = nil;
        BOOL result = [self.xmppStream authenticateWithFacebookAccessToken:facebook.accessToken error:&error];
        
        if (result == NO)
        {
            DDLogError(@"%@: Error in xmpp auth: %@", THIS_FILE, error);
        }
    } 
    DDLogVerbose(@"Did connect myJID = %@", [self.xmppStream.myJID full]);

    
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Facebook Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)fbDidLogin
{    
	DDLogVerbose(@"%@: %@\nFacebook login successful!", THIS_FILE, THIS_METHOD);	
	DDLogVerbose(@"%@: facebook.accessToken: %@", THIS_FILE, facebook.accessToken);
	DDLogVerbose(@"%@: facebook.expirationDate: %@", THIS_FILE, facebook.expirationDate);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];

    
	NSError *error = nil;
	if (![self.xmppStream connect:&error])
	{
		DDLogError(@"%@: Error in xmpp connection: %@", THIS_FILE, error);
	}
    DDLogVerbose(@"did login myJID = %@", [self.xmppStream.myJID full]);
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}


@end

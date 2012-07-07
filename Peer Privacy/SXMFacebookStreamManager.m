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
    if (![self.xmppStream isDisconnected]) {
		return YES;
	}

    DDLogVerbose(@"Facebook connect");
    facebook = [[Facebook alloc] initWithAppId:FACEBOOK_APP_ID andDelegate:self];
    
    if (self.account.configured) {
        DDLogVerbose(@"Using existing FB token: %@", self.account.accessToken);
        facebook.accessToken = self.account.accessToken;
        facebook.expirationDate = self.account.accessTokenExpirationDate;
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
    }
    
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
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
    self.account.streamBareJidStr = [self.xmppStream.myJID bare];
    DDLogVerbose(@"Saved streamBareJidStr from facebook graph api: %@", self.account.streamBareJidStr);

    [facebook requestWithGraphPath:@"me" andDelegate:self];

}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Facebook Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)fbDidLogin
{    
	DDLogVerbose(@"%@: %@\nFacebook login successful!", THIS_FILE, THIS_METHOD);	
	DDLogVerbose(@"%@: facebook.accessToken: %@", THIS_FILE, facebook.accessToken);
	DDLogVerbose(@"%@: facebook.expirationDate: %@", THIS_FILE, facebook.expirationDate);
    
    self.account.accessToken = [facebook accessToken];
    self.account.accessTokenExpirationDate = [facebook expirationDate];
    
	NSError *error = nil;
	if (![self.xmppStream connect:&error])
	{
		DDLogError(@"%@: Error in xmpp connection: %@", THIS_FILE, error);
	}
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Request Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Called just before the request is sent to the server.
 */
- (void)requestLoading:(FBRequest *)request{
    
}

/**
 * Called when the server responds and begins to send back data.
 */
- (void)request:(FBRequest *)request didReceiveResponse:(NSURLResponse *)response{
    
}

/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(FBRequest *)request didFailWithError:(NSError *)error{
    DDLogVerbose(@"FB requested failed with error: %@", error);
}

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array, a string, or a number,
 * depending on thee format of the API response.
 */
- (void)request:(FBRequest *)request didLoad:(id)result{
    
    self.account.configured = YES;
    self.account.userId = [result objectForKey:@"name"];
    [self saveContext];
    
    DDLogVerbose(@"Saved name from facebook graph api: %@", self.account.userId);
    
    [self fireCompletion:YES];	
    [self goOnline];
}

/**
 * Called when a request returns a response.
 *
 * The result object is the raw response from the server of type NSData
 */
- (void)request:(FBRequest *)request didLoadRawResponse:(NSData *)data{
    
}



@end

//
//  SXMStreamManager.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
#import "SXMAccount.h"
#import "SXMRosterCoreDataStorage.h"

@class SXMStreamCoordinator;

@interface SXMStreamManager : NSObject

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;
@property (nonatomic, strong) SXMRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

@property (nonatomic) BOOL allowSelfSignedCertificates;
@property (nonatomic) BOOL allowSSLHostNameMismatch;
@property (nonatomic) BOOL isXmppConnected;

@property (nonatomic, strong) SXMAccount *account;
@property (nonatomic, strong) SXMStreamCoordinator *streamCoordinator;
@property (nonatomic, strong) void (^connectCompletion)(BOOL connected);


- (void)saveContext;

- (XMPPStream *)allocateStream;
- (void)configureStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;

- (BOOL)connect;
- (void)disconnect;
- (BOOL)connectWithCompletion: (void (^)(BOOL connected))completion; 
- (void)fireCompletion: (BOOL)didConnect;

- (void) sendMessageWithBody: (NSString *)messageStr andJidStr: (NSString *)jidStr;

@end

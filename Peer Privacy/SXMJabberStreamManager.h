//
//  SXMJabberStreamManager.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMStreamManager.h"

@interface SXMJabberStreamManager : SXMStreamManager

@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *JID;

- (id) initWithJID: (NSString *)aJID andPassword: (NSString *) aPassword;

@end

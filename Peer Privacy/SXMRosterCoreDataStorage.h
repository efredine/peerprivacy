//
//  SXMRosterCoreDataStorage.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-08-01.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XMPPRosterCoreDataStorage.h"

@interface SXMRosterCoreDataStorage : XMPPRosterCoreDataStorage

@property (strong, nonatomic) NSMutableDictionary *pendingElements;

@end

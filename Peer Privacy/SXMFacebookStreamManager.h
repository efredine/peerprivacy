//
//  SXMFacebookStreamManager.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-17.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMStreamManager.h"
#import "FBConnect.h"

@interface SXMFacebookStreamManager : SXMStreamManager <FBSessionDelegate>

@property (nonatomic, strong) Facebook *facebook;

@end

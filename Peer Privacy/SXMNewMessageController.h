//
//  SXMNewMessageController.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPP.h"
#import "XMPPRosterCoreDataStorage.h"

@class SXMNewMessageController;
@protocol SXMNewMessageDelegate <NSObject>

- (void) SXMNewMessageController:(SXMNewMessageController *)sender withUser: (XMPPUserCoreDataStorageObject *)user;

- (void) SXMNewMessageControllerCancelled:(SXMNewMessageController *)sender;

@end


@interface SXMNewMessageController : UITableViewController <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>
{
	NSFetchedResultsController *fetchedResultsController;
    NSFetchedResultsController *searchFetchedResultsController;
}

@property (strong, nonatomic) id<SXMNewMessageDelegate> delegate;

@end

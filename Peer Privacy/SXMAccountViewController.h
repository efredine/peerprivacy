//
//  SXMAccountViewController.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SXMEditJabberAccountController.h"

@interface SXMAccountViewController : UITableViewController <NSFetchedResultsControllerDelegate, SXMNewJabbberAccountControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) SXMAccount *selectedAccount;

@end

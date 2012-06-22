//
//  SXMMasterViewController.h
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreData/CoreData.h>

#import "SXMSimpleConversationStarterController.h"

@interface SXMMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate,SXMConversationStarterDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

//
//  SXMNewMessageController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMNewMessageController.h"
#import "SXMAppDelegate.h"
#import "SXMMultiStreamManager.h"
#import "SXMStreamManager.h"
#import "XMPPFramework.h"
#import "DDLog.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif

@interface SXMNewMessageController ()
@property (strong, nonatomic) UISearchDisplayController *mySearchDisplayController;
@end

@implementation SXMNewMessageController

@synthesize delegate;
@synthesize mySearchDisplayController;

- (SXMAppDelegate *)appDelegate
{
	return (SXMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Cancel button to dismiss this view
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSelected:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44.0)];
    searchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.tableView.tableHeaderView = searchBar;
    
    self.mySearchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    self.mySearchDisplayController.delegate = self;
    self.mySearchDisplayController.searchResultsDataSource = self;
    self.mySearchDisplayController.searchResultsDelegate = self;

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    fetchedResultsController = nil;
    searchFetchedResultsController = nil;
    mySearchDisplayController = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - New message delegate

- (IBAction)cancelSelected:(id)sender
{
    NSLog(@"Cancel pressed.");
    [self.delegate SXMNewMessageControllerCancelled:self];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController * aFetchedResultsController = [self fetchedResultsControllerForTableView: tableView];

    XMPPUserCoreDataStorageObject *user = [aFetchedResultsController objectAtIndexPath:indexPath];
    
    [self.delegate SXMNewMessageController:self withUser:user];

}

#pragma mark - core data access helper

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [[XMPPRosterCoreDataStorage sharedInstance] mainThreadManagedObjectContext];
}

#pragma mark Helper functions for getting the right table view and fetched results controller

- (NSFetchedResultsController *)fetchedResultsControllerForTableView: (UITableView *) tableView
{
    return tableView == self.tableView ? self.fetchedResultsController : self.searchFetchedResultsController;
}

- (UITableView *)tableViewForFetchedResultsController: (NSFetchedResultsController *) aFetchedResultsController
{
    return aFetchedResultsController == self.fetchedResultsController ? self.tableView : self.mySearchDisplayController.searchResultsTableView;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsControllers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = [self managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
        
	}
	
	return fetchedResultsController;
}

- (NSFetchedResultsController *)searchFetchedResultsController
{
    NSManagedObjectContext *moc = [self managedObjectContext_roster];
    if (searchFetchedResultsController == nil) {
        NSLog(@"Reloading search controller");
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:moc];
        
       
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];	
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
        
        NSString *searchString = self.searchDisplayController.searchBar.text;
        if ([searchString length] > 0) {
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"displayName CONTAINS %@", searchString];
            [fetchRequest setPredicate:searchPredicate];
        }
        
		searchFetchedResultsController = [[NSFetchedResultsController alloc] 
                                          initWithFetchRequest:fetchRequest
                                          managedObjectContext:moc
                                          sectionNameKeyPath:nil
		                                  cacheName:nil];
		[searchFetchedResultsController setDelegate:self];
        
        NSError *error = nil;
		if (![searchFetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}

    }
    return searchFetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    UITableView * aTableView = [self tableViewForFetchedResultsController:controller];
	[aTableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewCell helpers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)configurePhotoForCell:(UITableViewCell *)cell user:(XMPPUserCoreDataStorageObject *)user
{
	// Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	
	if (user.photo != nil)
	{
		cell.imageView.image = user.photo;
	} 
	else
	{
        SXMStreamManager *streamManager = [[[self appDelegate] multiStreamManager] streamManagerforStreamBareJidStr:user.streamBareJidStr];
		NSData *photoData = [[streamManager xmppvCardAvatarModule] photoDataForJID:user.jid];
        
		if (photoData != nil)
			cell.imageView.image = [UIImage imageWithData:photoData];
		else
			cell.imageView.image = [UIImage imageNamed:@"defaultPerson"];
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView != self.tableView) {
        NSLog(@"Returning 1 section for table log view");
        return 1;
    }
    NSFetchedResultsController * aFetchedResultsController = [self fetchedResultsControllerForTableView: tableView];
	return [[aFetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{
    if (self.tableView != sender) {
        NSLog(@"Returning empty string for searchTableView section header");
        return @"";
    }
    
	NSArray *sections = [[self fetchedResultsController] sections];
	
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
		int section = [sectionInfo.name intValue];
		switch (section)
		{
			case 0  : return @"Available";
			case 1  : return @"Away";
			default : return @"Offline";
		}
	}
	
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    NSFetchedResultsController * aFetchedResultsController = [self fetchedResultsControllerForTableView: tableView];

	NSArray *sections = [aFetchedResultsController sections];
    int numRows = 0;
    
	if (sectionIndex < [sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
		numRows = sectionInfo.numberOfObjects;
	}
	
    NSLog(@"Section: %d, Rows: %d", sectionIndex, numRows);
	return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"NewMessageTableCell";
    
    NSLog(@"Requesting section: %d, row: %d", [indexPath section], [indexPath row]);
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:CellIdentifier];
	}
    
    NSFetchedResultsController * aFetchedResultsController = [self fetchedResultsControllerForTableView: tableView];
	
	XMPPUserCoreDataStorageObject *user = [aFetchedResultsController objectAtIndexPath:indexPath];
	
	cell.textLabel.text = user.displayName;
	[self configurePhotoForCell:cell user:user];
	
	return cell;
}

#pragma mark -
#pragma mark Content Filtering
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope
{
    NSLog(@"Setting searchFetch to nil through filter content");
    // update the filter, in this case just blow away the FRC and let lazy evaluation create another with the relevant search info
    searchFetchedResultsController.delegate = nil;
    searchFetchedResultsController = nil;
    // if you care about the scope save off the index to be used by the serchFetchedResultsController
    //self.savedScopeButtonIndex = scope;
}


#pragma mark -
#pragma mark Search Bar 
- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView;
{
    NSLog(@"Unloading search results");
    // search is done so get rid of the search FRC and reclaim memory
    searchFetchedResultsController.delegate = nil;
    searchFetchedResultsController = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSLog(@"shouldReloadTableForSearchString");
    [self filterContentForSearchText:searchString 
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSLog(@"shouldReloadForSearchScope");
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] 
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
   
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


@end

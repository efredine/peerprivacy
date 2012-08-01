//
//  SXMNewMessageController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-06-22.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMNewMessageController.h"
#import "SXMAppDelegate.h"
#import "SXMAccount.h"
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
    
    // Allocate and configure search display controller
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


#pragma mark - New message delegate

// Let delegate know dialog has been cancelled - delegate will dismiss dialog.
- (IBAction)cancelSelected:(id)sender
{
    [self.delegate SXMNewMessageControllerCancelled:self];
}


#pragma mark - Helper Methods

- (SXMAppDelegate *)appDelegate
{
	return (SXMAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [[SXMRosterCoreDataStorage sharedInstance] mainThreadManagedObjectContext];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsControllers
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 *  When using a UISearchDisplayController there are two views with two corresponding fetched results
 *  controllers.  The fetchedResultsController is for the underlying view that is displayed whenever
 *  the search controller is not active.  This view is displayed when the view first becomes active.
 *  
 *  The search fetched results controller provides the results for an active search.  These results
 *  are displayed in a view that overlays the original view.
 *
 *  The same table view delegate methods are called for both table views.  As such, the first thing
 *  the delegate methods do is retrieve the correct corresponding fetched results controller using
 *  fetchedResultsControllerForTableView.  The delegate methods for the fetched results controller
 *  do the inverse operation to retrieve the table view to reload.
 */

// Called by TableView delegate to retrieve the appropriate fetched results controller.
- (NSFetchedResultsController *)fetchedResultsControllerForTableView: (UITableView *) tableView
{
    return tableView == self.tableView ? self.fetchedResultsController : self.searchFetchedResultsController;
}

// Called by FetchedResultsController to retrieve the appropriate table view.
- (UITableView *)tableViewForFetchedResultsController: (NSFetchedResultsController *) aFetchedResultsController
{
    return aFetchedResultsController == self.fetchedResultsController ? self.tableView : self.mySearchDisplayController.searchResultsTableView;
}

// Results for the underlying view.
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
		                                                                          cacheName:@"NewMessageCache"];
		[fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
        
	}
	
	return fetchedResultsController;
}

// Search results.
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
            NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"displayName CONTAINS [cd] %@", searchString];
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
        SXMStreamManager *streamManager = [[[self appDelegate] streamCoordinator] streamManagerforStreamBareJidStr:user.streamBareJidStr];
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

/*
 *  Currently, the underlying view is sorted by status with a section for each status.  The search
 *  view is all one sections sorted by name.  The view delegate methods hanlde both - the 
 *  configuration and presence of sections (or not) is determined by the corresponding fetched
 *  results controller.
 */

// Tell the delegate the user has selected a user.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFetchedResultsController * aFetchedResultsController = [self fetchedResultsControllerForTableView: tableView];

    XMPPUserCoreDataStorageObject *user = [aFetchedResultsController objectAtIndexPath:indexPath];
    [self.delegate SXMNewMessageController:self withUser:user];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSFetchedResultsController * aFetchedResultsController = [self fetchedResultsControllerForTableView: tableView];
	return [[aFetchedResultsController sections] count];
}

// Only the underlying view has section titles.
- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{    
    if (sender == self.tableView) {
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
	
 	return numRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"NewMessageTableCell";
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
	}
    
    NSFetchedResultsController * aFetchedResultsController = [self fetchedResultsControllerForTableView: tableView];
	
	XMPPUserCoreDataStorageObject *user = [aFetchedResultsController objectAtIndexPath:indexPath];
    SXMAccount *account = [SXMAccount accountForStreamBareJidStr:user.streamBareJidStr inManagedObjectContext:[self appDelegate].managedObjectContext];
	
	cell.textLabel.text = user.displayName;
    cell.detailTextLabel.text = account.name;
//	[self configurePhotoForCell:cell user:user];
	
	return cell;
}

#pragma mark -
#pragma mark Search Bar
/*
 *  Search bar implementation proceeds by destroying and re-creating the fetched results controller
 *  every time the search phrase changes.  This is done by setting the searched results controller
 *  to nil which causes it to be re-initialized by the lazy initialization when called from the
 *  table view delegate methods.
 */

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope
{
    // update the filter, in this case just blow away the FRC and let lazy evaluation create another with the relevant search info
    searchFetchedResultsController.delegate = nil;
    searchFetchedResultsController = nil;
    // if you care about the scope save off the index to be used by the serchFetchedResultsController
    //self.savedScopeButtonIndex = scope;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView;
{
     // search is done so get rid of the search FRC and reclaim memory
    searchFetchedResultsController.delegate = nil;
    searchFetchedResultsController = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString 
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] 
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
   
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


@end

//
//  SXMAccountViewController.m
//  Peer Privacy
//
//  Created by Eric Fredine on 12-07-05.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SXMAccountViewController.h"
#import "SXMAppDelegate.h"
#import "SXMAccount.h"


@interface SXMAccountViewController ()
@end

@implementation SXMAccountViewController

@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize selectedAccount;

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
    
    self.managedObjectContext = [self appDelegate].managedObjectContext;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
{    
     NSArray *sections = [[self fetchedResultsController] sections];
    
    if (sectionIndex < [sections count])
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
        
        int section = [sectionInfo.name intValue];
        switch (section)
        {
            case 0  : return @"Select Account to Setup";
            case 1  : return @"In Use";
            default : return @"Huh?";
        }
    }
    return @"Unexpected";
}
	

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
    NSArray *sections = [[self fetchedResultsController] sections];
    
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
    NSString *cellIdentifier = nil;
    
    SXMAccount *account = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (account.configured) {
        if (account.accountType == kFacebookAccountType) {
            cellIdentifier = @"FacebookViewDetails";
        }
        else {
            cellIdentifier = @"JabberViewDetails";
        }
    }
    else {
        if (account.accountType == kFacebookAccountType) {
            cellIdentifier = @"ConfigureFacebook";
        }
        else {
            cellIdentifier = @"ConfigureJabber";
        }
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    cell.textLabel.text = account.name;
    
    return cell;
}



#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected account");
    self.selectedAccount = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return indexPath;
}


//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSLog(@"Selected account");
//    self.selectedAccount = [self.fetchedResultsController objectAtIndexPath:indexPath];
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"newJabberAccount"])
    {
        NSLog(@"Setting account");
        [(SXMNewJabberAccountController *)[[segue destinationViewController] topViewController] setDelegate:self];
        [(SXMNewJabberAccountController *)[[segue destinationViewController] topViewController] setAccount:self.selectedAccount];
    }
    else {
        [(SXMAccountDetailViewController *)[segue destinationViewController] setAccount:self.selectedAccount];
    }

}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SXMAccount" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"configured" ascending:YES];
    NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"configured" cacheName:@"SXMAccountView"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    // nothing more to do - so just a placeholder for now
}

#pragma mark new jabber account delegate

- (void)SXMNewJabbberAccountControllerCancelled:(id)sender
{
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (void)SXMNewJabbberAccountController:(SXMNewJabberAccountController *)sender withAccount:(SXMAccount *)account
{
    [self dismissViewControllerAnimated:YES completion: nil];
    [self.tableView reloadData];
    [[self appDelegate] saveContext];
}

@end

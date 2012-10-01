//
//  AddGameViewController.m
//  DGSPhone
//
//  Created by Justin Weiss on 6/28/10.
//  Copyright 2010 Justin Weiss. All rights reserved.
//

#import "AddGameViewController.h"
#import "TableCellFactory.h"
#import "LoginViewController.h"
#import "BooleanCell.h"

@implementation AddGameViewController

@synthesize descriptionCell, game;
@synthesize player = _player;

#pragma mark -
#pragma mark View lifecycle

typedef enum _AddGameSection {
	kDescriptionSection,
	kBoardSection,
	kTimeSection,
    kRatingSection
} AddGameSection;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.game = [[NewGame alloc] init];
    self.navigationItem.title = @"Create a Game";
    NSMutableArray *ratingStrings = [[NSMutableArray alloc] initWithCapacity:40];
    for (int i = 30; i > 0; i--) {
        [ratingStrings addObject:[NSString stringWithFormat:@"%d kyu", i]];
    }
    for (int i = 1; i < 10; i++) {
        [ratingStrings addObject:[NSString stringWithFormat:@"%d dan", i]];
    }
    _ratingStrings = ratingStrings;
    
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.player = [Player currentPlayer];
    if (!self.player.rated) {
        self.game.komiType = kKomiTypeManual;
    }
}

/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self deselectSelectedCell];
}

/*
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
*/
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (IBAction)addGame {
	[self showSpinner:@"Posting..."];
	[self.gs addGame:self.game onSuccess:^() {
		[self hideSpinner:YES];
		[[self navigationController] popToRootViewControllerAnimated:YES];
	}];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return kRatingSection + 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (section == kDescriptionSection) {
		return 1;
	} else if (section == kBoardSection) {
        if (self.game.komiType != kKomiTypeManual) {
			return 3;
		} else {
			return 6;
		}
	} else if (section == kTimeSection) {
		if (self.game.byoYomiType == kByoYomiTypeFischer) {
			return 3;
		} else {
			return 4;
		}
	} else if (section == kRatingSection) {
        if (self.game.requireRatedOpponent) {
            return 4;
        } else {
            return 2;
        }
    }
	return 0;
}

- (UITableViewCell *)defaultCell:(UITableView *)theTableView {
	static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }	
	return cell;
}

- (TextCell *)textCell:(UITableView *)theTableView {
	static NSString *CellIdentifier = @"TextCell";
    
    TextCell *cell = (TextCell *)[theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [[TextCell alloc] init];
    }
	
	return cell;
}

- (SelectCell *)selectCell:(UITableView *)theTableView {
	static NSString *CellIdentifier = @"SelectCell";
    
    SelectCell *cell = (SelectCell *)[theTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		cell = [TableCellFactory selectCell];
    }
    
    // only one of these should ever be set.
    cell.changedSelector = nil;
    cell.onChanged = nil;
	
	return cell;
}

- (BooleanCell *)booleanCell:(UITableView *)theTableView {
    BooleanCell *cell = (BooleanCell *)[theTableView dequeueReusableCellWithIdentifier:@"BooleanCell"];
    if (cell == nil) {
		cell = [[BooleanCell alloc] init];
    }
	
	return cell;
}

- (void)setComment:(TextCell *)commentCell {
	[self.game setComment:[[commentCell textField] text]];
}

- (void)setBoardSize:(SelectCell *)cell {
	NSString *boardSize = (cell.options)[0][[cell.picker selectedRowInComponent:0]];
	[self.game setBoardSize:[boardSize intValue]];
	cell.value.text = boardSize;
	cell.selectedOptions = @[boardSize];
}

- (void)setKomiType:(SelectCell *)cell {
    KomiType oldKomiType = self.game.komiType;
	KomiType komiType = [cell.picker selectedRowInComponent:0];

	NSString *komiTypeString = [self.game komiTypeString:komiType];
	self.game.komiType = komiType;
	cell.value.text = komiTypeString;
	cell.selectedOptions = @[komiTypeString];
    
    // We want to update the table cells without deselecting 
    // the current cell, so no #reloadData for you.
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:3 inSection:kBoardSection], [NSIndexPath indexPathForRow:4 inSection:kBoardSection], [NSIndexPath indexPathForRow:5 inSection:kBoardSection]];
    
    if (oldKomiType != kKomiTypeManual && komiType == kKomiTypeManual) {
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];                    
    } else if (oldKomiType == kKomiTypeManual && komiType != kKomiTypeManual) {
        [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)setByoYomiType:(SelectCell *)cell {
	ByoYomiType oldByoYomiType = self.game.byoYomiType;
	ByoYomiType byoYomiType = [cell.picker selectedRowInComponent:0];
	NSString *byoYomiTypeString = [self.game byoYomiTypeString:byoYomiType];
	self.game.byoYomiType = byoYomiType;
	cell.value.text = byoYomiTypeString;
	cell.selectedOptions = @[byoYomiTypeString];
	
	// We want to update the table cells without deselecting 
	// the current cell, so no #reloadData for you.
	NSMutableArray *indexPaths = [NSMutableArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:kTimeSection]];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:3 inSection:kTimeSection];
	if (oldByoYomiType == kByoYomiTypeFischer && byoYomiType != kByoYomiTypeFischer) {
		[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
		[indexPaths addObject:indexPath];
	} else if (oldByoYomiType != kByoYomiTypeFischer && byoYomiType == kByoYomiTypeFischer) {
		[self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
	} else {
		[indexPaths addObject:indexPath];
	}
	[self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)setMainTime:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.timeValue = timeValue;
	self.game.timeUnit = [cell.picker selectedRowInComponent:2];
	
    cell.value.text = [self.game timePeriodString:self.game.timeValue withTimeUnit:self.game.timeUnit];
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.timeUnit]];
}

- (void)setExtraTimeJapanese:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.japaneseTimeValue = timeValue;
	self.game.japaneseTimeUnit = [cell.picker selectedRowInComponent:2];
    
	cell.value.text = [self.game timePeriodString:self.game.japaneseTimeValue withTimeUnit:self.game.japaneseTimeUnit];
    cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.japaneseTimeUnit]];
}

- (void)setExtraTimeCanadian:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.canadianTimeValue = timeValue;
	self.game.canadianTimeUnit = [cell.picker selectedRowInComponent:2];
	
    cell.value.text = [self.game timePeriodString:self.game.canadianTimeValue withTimeUnit:self.game.canadianTimeUnit];
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.canadianTimeUnit]];
}

- (void)setExtraTimeFischer:(SelectCell *)cell {
	int tens = [[cell selectedValueInComponent:0] intValue];
	int ones = [[cell selectedValueInComponent:1] intValue];
	int timeValue = tens * 10 + ones;
	self.game.fischerTimeValue = timeValue;
	self.game.fischerTimeUnit = [cell.picker selectedRowInComponent:2];
	
	cell.value.text = [self.game timePeriodString:self.game.fischerTimeValue withTimeUnit:self.game.fischerTimeUnit];
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:self.game.fischerTimeUnit]];
}

- (void)setJapaneseTimePeriods:(TextCell *)timePeriodCell {
	[self.game setJapaneseTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (void)setCanadianTimePeriods:(TextCell *)timePeriodCell {
	[self.game setCanadianTimePeriods:[[[timePeriodCell textField] text] intValue]];
}

- (SelectCell *)timeCell:(UITableView *)theTableView timeValue:(int)timeValue timeUnit:(TimePeriod)timeUnit selector:(SEL)setSelector label:(NSString *)label {
	SelectCell *cell = [self selectCell:theTableView];
	NSString *timeString = [self.game timePeriodString:timeValue withTimeUnit:timeUnit];
	NSArray *zeroToNine = @[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9"];
	NSArray *timePeriods = @[[self.game timePeriodValue:kTimePeriodHours], [self.game timePeriodValue:kTimePeriodDays], [self.game timePeriodValue:kTimePeriodMonths]];
	NSArray *sizes = @[@80.0f,@80.0f, @140.0f];
	cell.label.text = label;
	cell.value.text = timeString;
	cell.changedSelector = setSelector;
	cell.sizes = sizes;
	cell.options = @[zeroToNine, zeroToNine, timePeriods];
	int tens = timeValue / 10;
	int ones = timeValue - (tens * 10);
	cell.selectedOptions = @[[NSString stringWithFormat:@"%d", tens], [NSString stringWithFormat:@"%d", ones], [self.game timePeriodValue:timeUnit]];
	return cell;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self textCell:theTableView];
	if ([indexPath section] == kDescriptionSection) {

		if ([indexPath row] == 0) {
			TextCell *cell = [self textCell:theTableView];
			cell.textLabel.text = @"Comment";
			cell.textField.text = self.game.comment;
			cell.textField.keyboardType = UIKeyboardTypeDefault;
			cell.textEditedSelector = @selector(setComment:);
			return cell;
		}
	}
	if ([indexPath section] == kBoardSection) {
		
		if ([indexPath row] == 0) {
			SelectCell *cell = [self selectCell:theTableView];
			NSString *boardSize = [NSString stringWithFormat:@"%d", self.game.boardSize];
			NSArray *options = @[@"9", @"13", @"19"];
			cell.label.text = @"Board Size";
			cell.value.text = boardSize;
			cell.changedSelector = @selector(setBoardSize:);
			cell.options = @[options];
			cell.sizes = nil;
			cell.selectedOptions = @[boardSize];
			return cell;
		} else if ([indexPath row] == 1) {
            BooleanCell *cell = [self booleanCell:theTableView];
            cell.textLabel.text = @"Standard Placement";
            cell.toggleSwitch.on = self.game.stdHandicap;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.stdHandicap = cell.toggleSwitch.on;
            };
			return cell;
		} else if ([indexPath row] == 2) {
			SelectCell *cell = [self selectCell:theTableView];
			NSString *komiType = [self.game komiTypeString];
			NSMutableArray *options = [NSMutableArray array];
            if (self.player.rated) {
                [options addObjectsFromArray:@[[self.game komiTypeString:kKomiTypeConventional], [self.game komiTypeString:kKomiTypeProper]]];
            } else {
                cell.userInteractionEnabled = NO;
            }
            [options addObject:[self.game komiTypeString:kKomiTypeManual]];
            cell.label.text = @"Komi Type";
			cell.value.text = komiType;
			cell.changedSelector = @selector(setKomiType:);
			cell.options = @[options];
			cell.selectedOptions = @[komiType];
			cell.sizes = nil;
			return cell;
		} else if ([indexPath row] == 3) {
            SelectCell *cell = [self selectCell:theTableView];
			NSString *manualKomiType = [self.game manualKomiTypeString];
            NSMutableArray *options = [NSMutableArray array];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeNigiri]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeDouble]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeBlack]];
            [options addObject:[self.game manualKomiTypeString:kManualKomiTypeWhite]];
                        
			cell.label.text = @"Game Style";
			cell.value.text = manualKomiType;
            cell.onChanged = ^(SelectCell *cell) {
                ManualKomiType manualKomiType = [cell.picker selectedRowInComponent:0];
                NSString *manualKomiTypeString = [self.game manualKomiTypeString:manualKomiType];
                self.game.manualKomiType = manualKomiType;
                cell.value.text = manualKomiTypeString;
                cell.selectedOptions = @[manualKomiTypeString];
            };
			cell.options = @[options];
			cell.selectedOptions = @[manualKomiType];
			cell.sizes = nil;
			return cell;
        } else if ([indexPath row] == 4) {
            SelectCell *cell = [self selectCell:theTableView];
            NSMutableArray *handicaps = [[NSMutableArray alloc] initWithObjects:@"0", nil];
            for (int i = 2; i < 22; i++) {
                [handicaps addObject:[NSString stringWithFormat:@"%d", i]];
            }
            
			cell.label.text = @"Handicap";
			cell.value.text = [NSString stringWithFormat:@"%d", self.game.handicap];
            cell.onChanged = ^(SelectCell *cell) {
                NSString *handicapString = [cell selectedValueInComponent:0];
                self.game.handicap = [handicapString intValue];
                cell.value.text = handicapString;
            };
			cell.options = @[handicaps];
			cell.selectedOptions = @[[NSString stringWithFormat:@"%d", self.game.handicap]];
			cell.sizes = nil;
			return cell;
        } else if ([indexPath row] == 5) {
            TextCell *cell = [self textCell:theTableView];
            cell.textLabel.text = @"Komi";
            cell.textField.text = [NSString stringWithFormat:@"%0.1f", self.game.komi];
            cell.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            cell.onChanged = ^(TextCell *cell) {
                self.game.komi = [cell.textField.text floatValue];
            };
            return cell;
        }
	} else if ([indexPath section] == kTimeSection) {
		if ([indexPath row] == 0) {
			return [self timeCell:theTableView timeValue:self.game.timeValue timeUnit:self.game.timeUnit selector:@selector(setMainTime:) label:@"Main Time"];
		} else if ([indexPath row] == 1) {
			SelectCell *cell = [self selectCell:theTableView];
			NSString *byoYomiType = [self.game byoYomiTypeString];
			NSArray *options = @[[self.game byoYomiTypeString:kByoYomiTypeJapanese], [self.game byoYomiTypeString:kByoYomiTypeCanadian], [self.game byoYomiTypeString:kByoYomiTypeFischer]];
			cell.label.text = @"Byo-Yomi";
			cell.value.text = byoYomiType;
			cell.changedSelector = @selector(setByoYomiType:);
			cell.options = @[options];
			cell.selectedOptions = @[byoYomiType];
			cell.sizes = nil;
			return cell;
		} else if ([indexPath row] == 2) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
				return [self timeCell:theTableView timeValue:self.game.japaneseTimeValue timeUnit:self.game.japaneseTimeUnit selector:@selector(setExtraTimeJapanese:) label:@"Extra Time"];
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
				return [self timeCell:theTableView timeValue:self.game.canadianTimeValue timeUnit:self.game.canadianTimeUnit selector:@selector(setExtraTimeCanadian:) label:@"Extra Time"];
			} else if (self.game.byoYomiType == kByoYomiTypeFischer) {
				return [self timeCell:theTableView timeValue:self.game.fischerTimeValue timeUnit:self.game.fischerTimeUnit selector:@selector(setExtraTimeFischer:) label:@"Extra Per Move"];
			}
		} else if ([indexPath row] == 3) {
			if (self.game.byoYomiType == kByoYomiTypeJapanese) {
				TextCell *cell = [self textCell:theTableView];
				cell.textLabel.text = @"Extra Periods";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.japaneseTimePeriods];
				cell.textEditedSelector = @selector(setJapaneseTimePeriods:);
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			} else if (self.game.byoYomiType == kByoYomiTypeCanadian) {
				TextCell *cell = [self textCell:theTableView];
				cell.textLabel.text = @"Extra Stones";
				cell.textField.text = [NSString stringWithFormat:@"%d", self.game.canadianTimePeriods];
				cell.textEditedSelector = @selector(setCanadianTimePeriods:);
				cell.textField.keyboardType = UIKeyboardTypeNumberPad;
				return cell;
			}
		}
	} if ([indexPath section] == kRatingSection) {
		if ([indexPath row] == 0) {
			BooleanCell *cell = [self booleanCell:theTableView];
            cell.textLabel.text = @"Ranked game";
            cell.toggleSwitch.on = self.game.rated;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.rated = cell.toggleSwitch.on;
            };
			return cell;
		} else if ([indexPath row] == 1) {
			BooleanCell *cell = [self booleanCell:theTableView];
            cell.textLabel.text = @"Rated opponent";
            cell.toggleSwitch.on = self.game.requireRatedOpponent;
            cell.onChanged = ^(BooleanCell *cell) {
                self.game.requireRatedOpponent = cell.toggleSwitch.on;
                // We want to update the table cells without deselecting 
                // the current cell, so no #reloadData for you.
                NSArray *indexPaths = @[[NSIndexPath indexPathForRow:2 inSection:kRatingSection], [NSIndexPath indexPathForRow:3 inSection:kRatingSection]];
                
                if (self.game.requireRatedOpponent) {
                    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];                    
                } else {
                    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                    [self deselectSelectedCell];
                }
            };
			return cell;
		} else if ([indexPath row] == 2) {
            SelectCell *cell = [self selectCell:theTableView];
			cell.label.text = @"Min rating";
			cell.value.text = self.game.minimumRating;
			cell.onChanged = ^(SelectCell *cell) {
                NSString *value = [cell selectedValueInComponent:0];
                self.game.minimumRating = value;
                cell.value.text = value;
            };
			cell.options = @[_ratingStrings];
			cell.selectedOptions = @[self.game.minimumRating];
			cell.sizes = nil;
			return cell;
        } else if ([indexPath row] == 3) {
            SelectCell *cell = [self selectCell:theTableView];
			cell.label.text = @"Max rating";
			cell.value.text = self.game.maximumRating;
            cell.onChanged = ^(SelectCell *cell) {
                NSString *value = [cell selectedValueInComponent:0];
                self.game.maximumRating = value;
                cell.value.text = value;
            };
			cell.options = @[_ratingStrings];
			cell.selectedOptions = @[self.game.maximumRating];
			cell.sizes = nil;
			return cell;
        }
    }
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
	self.descriptionCell = nil;
     _ratingStrings = nil;
}



@end



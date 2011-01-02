//
//  Table of waiting room games.
//

#import <UIKit/UIKit.h>
#import "JWTableViewController.h"
#import "DGS.h"

@interface WaitingRoomGamesController : JWTableViewController {
	DGS *dgs;
}

@property(nonatomic, retain) DGS *dgs;

@end

//
//  ChooseStringEncodingWindowController.h
//  HexFiend_2
//
//  Copyright 2010 ridiculous_fish. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class HFStringEncoding;

@interface ChooseStringEncodingWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
    IBOutlet NSTableView *tableView;
    IBOutlet NSSearchField *searchField;
}

// updates the current selection to the row that matches encoding (doesn't affect any documents)
- (void)setSelectedEncoding:(HFStringEncoding *)encoding;

@end

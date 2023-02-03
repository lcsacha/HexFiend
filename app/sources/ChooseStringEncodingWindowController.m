//
//  ChooseStringEncodingWindowController.m
//  HexFiend_2
//
//  Copyright 2010 ridiculous_fish. All rights reserved.
//

#import "ChooseStringEncodingWindowController.h"
#import "BaseDataDocument.h"
#import "AppDelegate.h"
#import <HexFiend/HFEncodingManager.h>



@interface HFEncodingChoice : NSObject
@property (readwrite, copy) NSString *label;
@property (readwrite) HFStringEncoding *encoding;
- (BOOL)matchesString:(NSString *)string;
- (BOOL)matchesEncoding:(HFStringEncoding *)encoding;
@end
@implementation HFEncodingChoice
- (BOOL)matchesString:(NSString *)string  {return ([self.encoding.name rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound || [self.encoding.identifier rangeOfString:string options:NSCaseInsensitiveSearch].location != NSNotFound);}
- (BOOL)matchesEncoding:(HFStringEncoding *)enc  {return [self.encoding isEqualTo:enc];}
@end



@implementation ChooseStringEncodingWindowController
{
    NSArray<HFEncodingChoice*> *encodings;
    NSArray<HFEncodingChoice*> *activeEncodings;
    
    BOOL _isUpdatingListOrSelection;
}

- (NSString *)windowNibName {
    return @"ChooseStringEncodingDialog";
}

- (void)populateStringEncodings {
    NSMutableArray<HFEncodingChoice*> *localEncodings = [NSMutableArray array];
    NSArray *systemEncodings = [HFEncodingManager shared].systemEncodings;
    for (HFNSStringEncoding *encoding in systemEncodings) {
        HFEncodingChoice *choice = [[HFEncodingChoice alloc] init];
        choice.encoding = encoding;
        if ([encoding.name isEqualToString:encoding.identifier]) {
            choice.label = encoding.name;
        } else {
            choice.label = [NSString stringWithFormat:@"%@ (%@)", encoding.name, encoding.identifier];
        }
        [localEncodings addObject:choice];
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES];
    [localEncodings sortUsingDescriptors:@[descriptor]];
    encodings = localEncodings;
    activeEncodings = encodings;
}

- (void)awakeFromNib {
    [self populateStringEncodings];
    [tableView reloadData];
    
    // register for notifications which indicate that we might need to update selected row (current document changed or encoding of current document changed)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeEncodingChanged:) name:BaseDataDocumentDidBecomeCurrentDocumentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activeEncodingChanged:) name:BaseDataDocumentDidChangeStringEncodingNotification object:nil];
}

- (void)showWindow:(id)sender {
    // make sure that the currently active encoding is selected in the table
    [self matchSelectionToActiveEncoding];
    
    [super showWindow:sender];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)__unused tableView
{
    return activeEncodings.count;
}

- (id)tableView:(NSTableView *)__unused tableView objectValueForTableColumn:(NSTableColumn *)__unused tableColumn row:(NSInteger)row
{
    NSString *identifier = tableColumn.identifier;
    if ([identifier isEqualToString:@"name"]) {
        return activeEncodings[row].encoding.name;
    } else if ([identifier isEqualToString:@"identifier"]) {
        return activeEncodings[row].encoding.identifier;
    } else {
        HFASSERT(0);
        return nil;
    }
}


- (BOOL)selectionShouldChangeInTableView:(NSTableView *)__unused tbl
{
    // always allow the selection to change if we are updating/filtering the list, or if changing selection to match current state
    if (_isUpdatingListOrSelection) {return TRUE;}
    
    // allow selection to change if user clicked on another valid row to switch encoding
    NSLog(@"selectionShouldChangeInTableView: -- clickedRow is %ld",[tableView clickedRow]);
    if ([tableView clickedRow] != -1) {return TRUE;}
    
    // also need to allow selection change if user is changing selection with up/down arrows
    NSLog(@"selectionShouldChangeInTableView: -- event type is %ld (NSEventTypeKeyDown is %ld)", [[[self window] currentEvent] type], NSEventTypeKeyDown);
    if ([[[self window] currentEvent] type] == NSEventTypeKeyDown) {return TRUE;}
    
    // prevent currently selected row from being deselected if user clicks in empty space below available encodings
    return FALSE;
}

- (void)tableViewSelectionDidChange:(NSNotification *)__unused notification
{
    // ignore the change if we are updating/filtering the list, or if changing selection to match current state
    if (_isUpdatingListOrSelection) {return;}
    
    // ignore if there is no longer a row selected
    NSInteger row = tableView.selectedRow;
    if (row == -1) {return;}
    
    /* Tell the front document (if any), otherwise tell the app delegate */
    HFStringEncoding *encoding = activeEncodings[row].encoding;
    BaseDataDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
    if (document) {
        HFASSERT([document isKindOfClass:[BaseDataDocument class]]);
        [document setStringEncoding:encoding];
    } else {
        [(AppDelegate *)[NSApp delegate] setStringEncoding:encoding];
    }
}


- (void)controlTextDidChange:(NSNotification * __unused)obj
{
    NSString *searchText = searchField.stringValue;
    if (searchText.length > 0) {
        NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(HFEncodingChoice *choice, NSDictionary * __unused dict) {return [choice matchesString:searchText];}];
        activeEncodings = [encodings filteredArrayUsingPredicate:filter];
    } else {activeEncodings = encodings;}
    
    _isUpdatingListOrSelection = TRUE;
    [tableView reloadData];
    [self matchSelectionToActiveEncoding];
    _isUpdatingListOrSelection = FALSE;
}


- (void)activeEncodingChanged:(NSNotification * __unused)note
{
    NSLog(@"Received activeEncodingChanged:notification");
    if (self.window.visible == TRUE) {[self matchSelectionToActiveEncoding];}
}

- (void)matchSelectionToActiveEncoding
{
    // get the current encoding from the front document (if any), otherwise get the current default encoding from the app delegate
    BaseDataDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
    HFStringEncoding *encoding;
    if (document) {
        HFASSERT([document isKindOfClass:[BaseDataDocument class]]);
        encoding = [document stringEncoding];
    } else {
        encoding = [(AppDelegate *)[NSApp delegate] defaultStringEncoding];
    }
    
    // we don't need to do anything if the currently selected row matches the current encoding
    if (encoding) {
     
        // TEMP:LCS (not implemetned yet)
        
    }
    
    _isUpdatingListOrSelection = TRUE;
    
    // select the current encoding in the list if it hasn't been filtered away, otherwise deselect all
    if (encoding) {
        // get the index of the first encoding choice that matches the current encoding
        NSUInteger row = [activeEncodings indexOfObjectPassingTest:^BOOL(HFEncodingChoice *choice, NSUInteger __unused idx, BOOL *__unused stop) {return [choice matchesEncoding:encoding];}];
        NSLog(@"matchSelectionToActiveEncoding -- row matching encoding is %ld", row);
        if (row != NSNotFound) {[tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:FALSE];}
        else {[tableView deselectAll:self];}    // current encoding is not in the filtered list
    } else {
        HFASSERT(0);    // there should always be a valid encoding from either a document or the app delegate
        [tableView deselectAll:self];
    }
    
    _isUpdatingListOrSelection = FALSE;
    return;
}


@end

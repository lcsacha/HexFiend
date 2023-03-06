//
//  MyDocumentController.h
//  HexFiend_2
//
//  Copyright 2010 ridiculous_fish. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BaseDataDocument;


extern NSString * const MDCCurrentDocumentDidChangeNotification;    // this notification occurs when a document's window becomes or resigns main (which also happens when switching between applications)


/* We subclass NSDocumentController to work around a bug in which LS crashes when it tries to fetch the icon for a block device. */
@interface MyDocumentController : NSDocumentController

/* Similar to TextEdit */
- (BaseDataDocument *)transientDocumentToReplace;

@end

//
//  Growl2View.h
//  Growler
//
//  Created by Aditya Mukherjee on 25/06/09.
//  Copyright (c) 2009. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Webkit/Webkit.h>
#import <Growl/Growl.h>

@interface GrowlerView : NSView <WebPlugInViewFactory, GrowlApplicationBridgeDelegate> { }
- (void) growl : (WebScriptObject *)values;
@end
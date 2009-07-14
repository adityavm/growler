//
//  GrowlerView.h
//  Growler
//
//  Created by Aditya Mukherjee on 08/07/09.
//  Copyright 2009 All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Growl/Growl.h>

@interface NSObject (gpGrowler)
- (void) my_webView:(id)arg1 didClearWindowObject:(id)arg2 forFrame:(id)arg3;
@end

@interface Growler : NSView <GrowlApplicationBridgeDelegate> {
	id _windowObj;
}
- (void) setWindow : (id) arg;
- (id) getFavicon;
- (BOOL) isKeyDefined: (id)aKey forValues:(id)values;

- (void) growl : (WebScriptObject *) values;//for internal calls
- (void) showGrowlNotification : (WebScriptObject *) values;//for fluid
- (void) showNotification : (NSString *)arg1 :(NSString *)arg2 :(NSString *)arg3;//for prism
- (void) growler : (WebScriptObject *) values;//for my own namespace
@end

@interface InTheBeginning : NSObject { }
@end
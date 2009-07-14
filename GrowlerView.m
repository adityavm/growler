//
//  GrowlerView.m
//  Growler
//
//  Created by Aditya Mukherjee on 08/07/09.
//  Copyright 2009 All rights reserved.
//

#import "GrowlerView.h"
#import </usr/include/objc/objc-class.h>

static BOOL PerformSwizzle(Class aClass, SEL orig_sel, SEL alt_sel, BOOL forInstance) {
    // First, make sure the class isn't nil
	if (aClass) {
		Method orig_method = nil, alt_method = nil;

		// Next, look for the methods
		if (forInstance) {
			orig_method = class_getInstanceMethod(aClass, orig_sel);
			alt_method = class_getInstanceMethod(aClass, alt_sel);
		} else {
			orig_method = class_getClassMethod(aClass, orig_sel);
			alt_method = class_getClassMethod(aClass, alt_sel);
		}

		// If both are found, swizzle them
		if (orig_method && alt_method) {
			IMP temp;

			temp = orig_method->method_imp;
			orig_method->method_imp = alt_method->method_imp;
			alt_method->method_imp = temp;
			return YES;
		} else {
			// This bit stolen from SubEthaFari's source
			NSLog(@"Growler: Original (selector %s) %@, Alternate (selector %s) %@",
				  orig_sel,
				  orig_method ? @"was found" : @"not found",
				  alt_sel,
				  alt_method ? @"was found" : @"not found");
		}
	} else {
		NSLog(@"%@", @"Growler Error: No class to swizzle methods in");
	}

	return NO;
}

@implementation InTheBeginning

+ (void) load {
	NSLog(@"%@", @"Plug-in Loaded");

	PerformSwizzle(NSClassFromString(@"LocationChangeHandler"), 
					@selector(webView:didClearWindowObject:forFrame:), 
					@selector(my_webView:didClearWindowObject:forFrame:), 
					YES);
	
	/* because this is called for plug-in initialization but
	 * Growler is out actual delegate. So I'm doing it here
	 */
	NSLog(@"Hello from Growler");//phew, it works
	NSString *growlPath = [[[NSBundle bundleForClass:[Growler class]] privateFrameworksPath]
							stringByAppendingPathComponent:@"Growl-WithInstaller.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];//to dynamically link to the framework
	if (growlBundle && [growlBundle load])
		[NSClassFromString(@"GrowlApplicationBridge") setGrowlDelegate:[[Growler alloc] init]]; // Register Growler as a Growl delegate
	else
		NSLog(@"Could not load Growl.framework");
}
@end

@implementation Growler

+ (void) initialize { }

- (void) setWindow : (id) arg {
	_windowObj = arg;
}

- (id) getFavicon {
	return [@"http://" stringByAppendingString:[[[[_windowObj valueForKey:@"window"] valueForKey:@"location"] valueForKey:@"host"] stringByAppendingString:@"/favicon.ico"]];
}

- (BOOL) isKeyDefined:(id)aKey forValues:(id)values{
	BOOL result = YES;
	@try {
		[values valueForKey:aKey];
	} @catch (NSException *e) {
		result = NO;
	}
	return result;
}

- (NSDictionary *) registrationDictionaryForGrowl {//register the kind of notifications that Growl will get from us
// TODO: Differentiate notifications for different 
//		apps to allow fine tuning from Growl preferences

		NSArray *notifications;
		notifications = [NSArray arrayWithObject: @"Web Application"];
		NSDictionary *dict;
		dict = [NSDictionary dictionaryWithObjectsAndKeys:
			notifications, GROWL_NOTIFICATIONS_ALL,
			notifications, GROWL_NOTIFICATIONS_DEFAULT, nil];
		
		return (dict);
}

// Decide which methods will be exposed to JavaScript code
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector
{
    if (selector == @selector(showGrowlNotification:) ||
		selector == @selector(showNotification:::) ||
		selector == @selector(growler:))
        return NO;
        
    return YES;
}

// Produce JavaScript-readable function names that will be
// mapped to our exposed plug-in methods
+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(showGrowlNotification:))
		return @"showGrowlNotification";
	else if (sel == @selector(showNotification:::))
		return @"showNotification";
	else if (sel == @selector(growler:))
		return @"growler";
    
    return nil;
}

// Requested by the hosting Web Kit application to make JavaScript access possible
- (id)objectForWebScript
{
    return self;
}

- (void) growl : (WebScriptObject *) values {
	NSLog(@"icon: %@", [self getFavicon]);
	[NSClassFromString(@"GrowlApplicationBridge")
		notifyWithTitle: [values valueForKey:@"title"]
		description: [values valueForKey:@"description"]//epic wtf material
		notificationName: @"Web Application"
		iconData: ([self isKeyDefined:@"icon" forValues:values]) 
								? [NSData dataWithContentsOfURL:[NSURL URLWithString:[values valueForKey:@"icon"]]] 
								: [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getFavicon]]]
		priority: 0
		isSticky: ([self isKeyDefined:@"sticky" forValues:values]) 
								? [[values valueForKey:@"sticky"] boolValue] 
								: NO
		clickContext: nil];
}

- (void) showGrowlNotification : (WebScriptObject *) values {
	[self growl:values];
}

- (void) showNotification : (NSString *)arg1 :(NSString *)arg2 :(NSString *)arg3 {
/* TODO: make this call to `[self growl]`, without crashing */
	NSData *icon;
	icon = ([arg3 isKindOfClass:NSClassFromString(@"WebUndefined")]) 
			? [NSData dataWithContentsOfURL:[NSURL URLWithString:[self getFavicon]]] 
			: [NSData dataWithContentsOfURL:[NSURL URLWithString:arg3]];
	
	[NSClassFromString(@"GrowlApplicationBridge")
		notifyWithTitle:arg1
		description:arg2
		notificationName:@"Web Application"
		iconData:icon
		priority:0
		isSticky:NO
		clickContext:nil];
	//[self growl:values];
}

- (void) growler : (WebScriptObject *) values {
	[self growl:values];
}
@end

@implementation NSObject (gpGrowler)

- (void) my_webView:(id)arg1 didClearWindowObject:(id)arg2 forFrame:(id)arg3 { // this is SPARTA!
	Growler *m = [[Growler alloc] init];
	[m setWindow:arg2];
	[arg2 setValue:m forKey:@"fluid"];
	[arg2 setValue:m forKey:@"platform"];
	[arg2 setValue:m forKey:@"growler"];
	[self my_webView:arg1 didClearWindowObject:arg2 forFrame:arg3];
}

@end
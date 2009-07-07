#import "GrowlerView.h"

@implementation GrowlerView

+ (NSView *)plugInViewWithArguments:(NSDictionary *)arguments
{
    return [[[self alloc] initWithFrame:NSZeroRect] autorelease];
}

/*
 * Optional WebPlugIn methods
 * Implement these to respond to various events 
 * during your plug-in's life cycle
 */
- (void)webPlugInInitialize
{
	NSLog(@"Hello from Growler.plugin");//phew, it works
	NSString *growlPath = [[[NSBundle bundleForClass:[self class]] privateFrameworksPath]
								stringByAppendingPathComponent:@"Growl-WithInstaller.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];//to dynamically link to the framework

	if (growlBundle && [growlBundle load]) {
		// Register ourselves as a Growl delegate
		[NSClassFromString(@"GrowlApplicationBridge") setGrowlDelegate:self];
	} else {
		NSLog(@"Could not load Growl.framework");
	}
}
/*
- (void) webView: (WebView *)sender 
			windowScriptObject:(WebScriptObject *) windowScriptObject {
	[windowScriptObject setValue:self forKey:@"foo"];
}*/

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
    if (selector == @selector(growl:))
        return NO;
        
    return YES;
}

// Produce JavaScript-readable function names that will be
// mapped to our exposed plug-in methods
+ (NSString *)webScriptNameForSelector:(SEL)sel
{
    if (sel == @selector(growl:))
		return @"showGrowlNotification";
    
    return nil;
}

// Requested by the hosting Web Kit application to make JavaScript access possible
- (id)objectForWebScript
{
    return self;
}

- (void) growl :(WebScriptObject *)values {
// TODO: Allow sticky
	NSData *icon;
	@try {
		icon = [NSData dataWithContentsOfURL:[NSURL URLWithString:[values valueForKey:@"icon"]]];
	} @catch (NSException *e) {
		NSString *iconPath = [[NSBundle bundleForClass:[self class]]
								pathForResource:@"Growler" ofType:@"png"];
		icon = [NSData dataWithContentsOfFile:iconPath];
	} @finally {
	
	//icon = [NSData dataWithContentsOfURL:[NSURL URLWithString:[values valueForKey:@"icon"]]];
	[NSClassFromString(@"GrowlApplicationBridge")
		notifyWithTitle:[values valueForKey:@"title"]
		description:[values valueForKey:@"description"]
		notificationName:@"Web Application"
		iconData:icon
		priority:0
		isSticky:NO
		clickContext:nil];
	}
}
@end
#import <dlfcn.h>
#import <SpringBoard/SpringBoard.h>
#include "substrate.h"
#import "notify.h"
@interface SBIconView : SBIcon {}
@end
#define __DEBUG_LOG__
#ifndef __DEBUG_LOG__
/*
 * Fucking NSLog.
 */
void null__(id a) {};
#define NSLog(x, ...) null__(x)
#endif
@interface SBAppSwitcherBarView : UIView {
}
+(id)mesg;
+(CGRect)_iconFrameForIndex:(unsigned)index withSize:(CGSize)size;
@end
@interface UIToggle : NSObject {
	void* lib_handle;
}
-(UIToggle*)initWithName:(NSString*)name;
@end


@interface Hook : NSObject {
	UIButton* triggerButton;
	UIView* contentView;
	SBIconLabel* label;
}
+(Hook*)sharedHook;
@end
@interface UISettingsToggleController : NSObject {
	UIScrollView* toggleContainer;
	NSMutableArray* toggleArray;
	NSMutableArray* dispatcherArray;
	UIWindow* toggleWindow;
}
+ (UISettingsToggleController*)sharedController;
-(void)load;
-(CGRect)autoRect;
-(UIButton*)createToggleWithAction:(SEL)action title:(NSString*)title target:(id)target;
@end
static UIButton* triggerButton;
@interface UISettingsCore : NSObject {
	UIView* contentView;
	SBIconLabel* label;
	NSMutableArray* toggles;
	NSMutableArray* viewsInOriginalMenu;
	UIScrollView* toggleContainer;
	id hook;
	int state;
}
+ (UISettingsCore*)sharedSettings;
- (void)hook:(id)sender;
- (void)creatr;
-(NSMutableArray*) dylibs;
@end

@implementation UISettingsCore
static UISettingsCore* sharedInstance = nil;
-(BOOL)doIhazToggles {
	if ([[self dylibs] count]==0) {
		return NO;
	}
	return YES;
}
-(UIScrollView*)toggleContainer{
	return toggleContainer;
}
static NSMutableArray* kDylibList=nil;
-(NSMutableArray*) dylibs
{
	if (kDylibList==nil) {
		NSLog(@"[UICore]: Initializing dylibs array");
		kDylibList=[[NSMutableArray alloc] init];
		NSFileManager* fm = [[[NSFileManager alloc] init] autorelease];
		NSEnumerator *e = [[fm contentsOfDirectoryAtPath:@"/Library/UISettings/" error:nil] objectEnumerator];
		while (NSString* path=[e nextObject]) {
			if ([[path pathExtension] isEqualToString: @"dylib"]) {
				[kDylibList addObject:path];
			}
		}		
	}
	return kDylibList;
}
-(void)creatr
{
	if(state!=1){
		NSEnumerator *e;
		e=[[self dylibs] objectEnumerator];
		while (NSString* path=[e nextObject]) {
			NSLog(@"[UICore]: Loading dylib %@", path);
			[[UIToggle alloc] initWithName:path];
			NSLog(@"[%@]: Loaded", path);
		}
		state=1;
	}
}
-(void)hookInBackground
{
	NSAutoreleasePool *pool;
	pool=[[NSAutoreleasePool alloc] init];
	//CGRect frame;
	toggleContainer = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 6, 316, 85)];
	toggleContainer.bounces = YES;
	toggleContainer.contentSize = CGSizeMake(contentView.frame.size.width, contentView.frame.size.height);	
	[contentView addSubview:toggleContainer];
	[self creatr];
	[pool drain];
}
-(void)hook:(id)sender {
	if ([self doIhazToggles]==YES) {
		/*
		 * FAST_ALPHA - Multithreaded, non-locking dylib loader.
		 * There are known bugs for it w/ the new dynamic image patch
		 * If you want to use it, #define FAST_ALPHA 1
		 * FIXME: FIX CRASHES
		 */
		if(!toggleContainer){
			#ifdef FAST_ALPHA
				[self performSelectorInBackground:@selector(hookInBackground) withObject:nil];
			#else
				[self performSelector:@selector(hookInBackground) withObject:nil];
			#endif
		}
	}  else {
		[[[UIAlertView alloc] initWithTitle:@"UISettings - Simple Settings System in SpringBoard" message:@"Hello. You don't have any toggle. UISettings needs some toggles. Go grab them on Cydia." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] show];
	}
}
-(UISettingsCore*) init {
	[super init];
	state=0;
	Class Hook=objc_getClass("Hook");
	hook=[Hook sharedHook];
	contentView=MSHookIvar<UIView*>(hook, "contentView");
	label=MSHookIvar<SBIconLabel*>(hook, "label");
	triggerButton=MSHookIvar<UIButton*>(hook, "triggerButton");
	return self;
}
+ (UISettingsCore*)sharedSettings
{
	if (sharedInstance == nil) {
		sharedInstance = [[self alloc] init];
		//[sharedInstance load];
    }
    return sharedInstance;
}
@end
// vim:ft=objc

@implementation UIToggle

-(UIToggle*)initWithName:(NSString*)name
{
	[self init];
	NSString *fpath=[@"/Library/UISettings/" stringByAppendingString:name];
	lib_handle = dlopen([fpath UTF8String], RTLD_LAZY | RTLD_LOCAL);
	if (!lib_handle) {
		NSLog(@"[UICore]: Error: %s", dlerror());
		return nil;
	}
	return self;
}


@end


@implementation UISettingsToggleController
static UISettingsToggleController* sharedIInstance = nil;

+ (UISettingsToggleController*)sharedController
{
    @synchronized(self)
    {
        if (sharedIInstance == nil) {
			sharedIInstance = [[self alloc] init];
			[sharedIInstance load];
		}
    }
	NSLog(@"StillAlive here");
    return sharedIInstance;
}
-(void)load
{
	@try {
	toggleWindow=[[objc_getClass("SBUIController") sharedInstance] performSelector:@selector(window)];
	}
	@catch (id e)
	{
	toggleWindow=[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	toggleWindow.windowLevel = (unsigned int)-1;
	toggleWindow.hidden = NO;
	toggleWindow.userInteractionEnabled = NO;
	}
}
#pragma mark coreDispatcher
-(void)coreDispatcher:(UIButton*)sender {
	NSEnumerator *e = [dispatcherArray objectEnumerator];
	NSArray* object;
	while ((object = [e nextObject])) {
		if ([object objectAtIndex:0]==sender) {
			NSLog(@"CoreDispatcher: found selector");
			if (sender.tag==0) {
				[[object objectAtIndex:2] performSelector:NSSelectorFromString([object objectAtIndex:1 ])];
				
			} else {
				[[object objectAtIndex:2] performSelector:NSSelectorFromString([object objectAtIndex:1 ]) withObject:[[NSNumber alloc ]initWithInt:sender.tag]];
			}
			
			break;
		}
	}	
}
#pragma mark AddStuff
-(UIButton*)createToggleWithAction:(SEL)action title:(NSString*)title target:(id)target {
	// FIXME: correct this shit
	id hokr = [UISettingsCore sharedSettings];
	toggleContainer=MSHookIvar<UIScrollView*>(hokr, "toggleContainer"); // b00m
	if(!toggleContainer)
	{
		NSLog(@"ToggleContainer is nil");
	}
	if(toggleArray==nil) {
		NSLog(@"Initializing Array");
		toggleArray = [[NSMutableArray alloc] init];  
	}
	if(dispatcherArray==nil) {
		NSLog(@"Initializing Array");
		dispatcherArray = [[NSMutableArray alloc] init];  
	}
	// Dispatcher
	UIButton *myButton;
	if(title==nil){
		myButton = [UIButton buttonWithType:UIButtonTypeCustom];
	} else {
		myButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		myButton.titleLabel.adjustsFontSizeToFitWidth = TRUE;
		myButton.titleLabel.lineBreakMode = UILineBreakModeWordWrap;
		myButton.titleLabel.numberOfLines = 3; // maximum: 3!
		myButton.titleLabel.textAlignment = UITextAlignmentCenter;
	}
	myButton.frame = [self autoRect];
	myButton.tag=0;
	[myButton setTitle:title forState:UIControlStateNormal];
	[myButton addTarget:self action:@selector(coreDispatcher:) forControlEvents:UIControlStateSelected];
	[toggleContainer addSubview:myButton];
	NSArray* dispatcherElement=[[NSArray alloc] initWithObjects:myButton,NSStringFromSelector(action), target, nil];
	[dispatcherArray addObject:dispatcherElement];
	[toggleArray addObject:myButton];  
	return myButton;
}
-(UILabel*)createLabelForButton:(UIButton*)button text:(NSString*)text
{
	id hokr = [UISettingsCore sharedSettings];
	toggleContainer=MSHookIvar<UIScrollView*>(hokr, "toggleContainer"); // b00m
	UILabel *lbel = [ [UILabel alloc ] initWithFrame:CGRectMake(0.0, 0.0, 54.0, 24.0) ];
	lbel.textAlignment =  UITextAlignmentCenter;
	lbel.textColor = [UIColor whiteColor];
	lbel.backgroundColor = [UIColor clearColor];
	lbel.font = [UIFont boldSystemFontOfSize:(12.0)];
	[toggleContainer addSubview:lbel];
	CGPoint cer=button.center;
	cer.y+=(button.size.height/2)+6;
	lbel.center=cer;
	lbel.text = text;
	lbel.numberOfLines = 1;
	lbel.minimumFontSize=5.0;
	lbel.adjustsFontSizeToFitWidth=YES;
	//lbel.alpha=0.6;
	return lbel;
}
-(void)createToggleWithTitle:(NSString*)title andImage:(NSString*)path andSelector:(SEL)selector toTarget:(id)target
{
	NSAutoreleasePool* apool=[NSAutoreleasePool new];
	id button=[self createToggleWithAction:selector title:nil target:target];
	[self createLabelForButton:button text:title];
	NSData *imageData = [NSData dataWithContentsOfFile:path];
	UIImage *image = [UIImage imageWithData:imageData];
	[button setImage:image forState:UIControlStateNormal];
	[apool drain];
}
-(CGRect)autoRect {
	toggleContainer.contentSize = CGSizeMake((10+56)*([toggleArray count]+1)+5, toggleContainer.frame.size.height);
	return CGRectMake((10+56)*([toggleArray count])+5, 0, [objc_getClass("SBIconView") defaultIconImageSize].width, [objc_getClass("SBIconView") defaultIconImageSize].height);
}
@end

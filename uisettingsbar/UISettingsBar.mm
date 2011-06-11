#import "notify.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BBWeeAppController-Protocol.h"
#import "dlfcn.h"
#define kHookVer "Bar-0.1"
static BOOL initialized=NO;
@interface Core : NSObject {
	void* handler;
}
-(void*)coreIfOpen;
-(Class)CoreClass;
-(Core*)initWithPath:(NSString*)path;
@end
@implementation Core
-(Core*)initWithPath:(NSString*)path
{
	handler = dlopen([path UTF8String], RTLD_LOCAL);
	if (!handler) {
		NSLog(@"[UIHook:%s] Error hooking Core: %s", kHookVer, dlerror());
		return nil;
	}
	return self;
}
-(Class)CoreClass
{
	return objc_getClass("UISettingsCore");
}
-(void*)coreIfOpen {
	if (!handler) {
		NSLog(@"[UIHook:%s] Warning: Core isn't open", kHookVer);
		return nil;
	}
	return handler;
}
@end

// UICore <====> UIHook helper

@interface Hook : NSObject {
	id triggerButton;
	UIView* contentView;
	id label;
}
+(Hook*)sharedHook;
-(void)setView:(UIView*)vw;
@end

@implementation Hook
static Hook* sHook=nil;
+(Hook*)sharedHook
{
	if (sHook==nil) {
	sHook=[self new];
	}
    return sHook;
}
-(void)setView:(UIView*)vw
{
	triggerButton=nil;
	label=nil;
	contentView=vw;
}
@end

@interface UISettingsCore : NSObject
{
}
+(id)sharedSettings;
-(void)hook:(id)unused;
@end
@interface UISettingsBarConroller : NSObject <BBWeeAppController>
{
    UIView *_view;
}

+ (void)initialize;
- (UIView *)view;

@end

@implementation UISettingsBarConroller

+ (void)initialize
{
    
}

- (void)dealloc
{
    [_view release];
    [super dealloc];
}

- (void)viewWillAppear
{
	notify_post("com.qwerty.uisettings.reload");
	if(!initialized){	 
        	Core* SettingsHandler=[[Core alloc] initWithPath:@"/Library/UISettings/UICore/UICore.dylib"];
        	NSLog(@"Core bootstrapped");
        	Class UISettingsCore=[SettingsHandler CoreClass];
		[[Hook sharedHook] setView:[self view]];
		[[UISettingsCore sharedSettings] hook:nil];
		[SettingsHandler release];
	}
}

- (UIView *)view
{
    if (_view == nil)
    {
        _view = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, [self viewHeight])];
        UIImage *bg = [UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/UISettingsBar.bundle/UISettingsBackground.png"];
        UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
        bgView.frame = CGRectMake(0, 0, 316, [self viewHeight]);
        [_view addSubview:bgView];
        [bgView release];
        
    }    
    return _view;
}

- (float)viewHeight
{
    return 87.0f;
}

@end

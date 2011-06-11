#import "UIToggle.h"
#import "substrate.h"
#import <notify.h>
#import <unistd.h>
#import <GraphicsServices/GraphicsServices.h>
#import "MediaPlayer/MediaPlayer.h"
#define DETACH_THREAD _DETACH_THREAD(nil)
#define _DETACH_THREAD(x) if([NSThread isMainThread]){ [self performSelectorInBackground:_cmd withObject:x]; return; }
static id bluetooth;
static id wifi_on=nil;
static id wifi_off=nil;
static id bluetooth_on=nil;
static id bluetooth_off=nil;
static id airplane_on=nil;
static id airplane_off=nil;
void refresh_(__CFNotificationCenter* b, void* c, const __CFString* d, const void* e, const __CFDictionary* a);
void refresh();
@class SBPowerDownView;
@interface BluetoothManager : NSObject {
}
+(id)sharedInstance;
-(BOOL)powered;
-(BOOL)setPowered:(BOOL)powered;
@end
@interface SBUIController : NSObject {}
+(id)sharedInstance;
@end
@interface SpringBoard {}
+(id)sharedBoard;
@end
@interface SBTelephonyManager {}
+ (id)sharedTelephonyManager;
- (void)setIsInAirplaneMode:(BOOL)fp8;
- (BOOL)isInAirplaneMode;
+ (id)sharedTelephonyManagerCreatingIfNecessary:(BOOL)fp8;
- (void)updateAirplaneMode;
- (void)airplaneModeChanged;
@end
@interface SBPowerDownController : NSObject
{
    int _count;
    id _delegate;
    SBPowerDownView *_powerDownView;
    BOOL _isFront;
}

+ (id)sharedInstance;
- (void)dealloc;
- (double)autoLockTime;
- (BOOL)isOrderedFront;
- (void)orderFront;
- (void)orderOut;
- (id)powerDownViewWithSize:(struct CGSize)fp8;
- (void)activate;
- (void)_restoreIconListIfNecessary;
- (void)deactivate;
- (id)alertDisplayViewWithSize:(struct CGSize)fp8;
- (void)alertDisplayWillBecomeVisible;
- (void)setDelegate:(id)fp8;
- (void)powerDown;
- (void)cancel;

@end

@interface SBWiFiManager : NSObject {
}
+(id)sharedInstance;
-(id)init;
-(void)scan;
-(BOOL)joining;
-(BOOL)wiFiEnabled;
-(void)setWiFiEnabled:(BOOL)enabled;
-(int)signalStrengthBars;
-(int)signalStrengthRSSI;
-(void)updateSignalStrength;
-(void)_updateSignalStrengthTimer;
-(void)cancelTrust:(BOOL)trust;
-(void)acceptTrust:(id)trust;
-(void)cancelPicker:(BOOL)picker;
-(void)userChoseNetwork:(id)network;
-(id)knownNetworks;
-(void)resetSettings;
-(void)_scanComplete:(CFArrayRef)complete;
-(void)joinNetwork:(id)network password:(id)password;
-(void)_askToJoinWithID:(unsigned)anId;
@end
@interface SBBrightnessController : NSObject {
	BOOL _debounce;
}
+(id)sharedBrightnessController;
-(float)_calcButtonRepeatDelay;
-(void)adjustBacklightLevel:(BOOL)level;
-(void)_setBrightnessLevel:(float)level showHUD:(BOOL)hud;
-(void)setBrightnessLevel:(float)level;
-(void)increaseBrightnessAndRepeat;
-(void)decreaseBrightnessAndRepeat;
-(void)handleBrightnessEvent:(GSEventRef)event;
-(void)cancelBrightnessEvent;
@end
static id airplane=nil;
static id wifi=nil;
@interface UIToggleContr : NSObject  <UIActionSheetDelegate> {
	UIActionSheet *alert;
}
-(void)respring;
@end
@interface UIDevice (UISettings)
-(void)_setBacklightLevel:(float)level;
-(float)_backlightLevel;
@end
@implementation UIToggleContr
-(void)popup
{
	Class UISettingsToggleController = objc_getClass("UISettingsToggleController");
	alert=[[UIActionSheet alloc] initWithTitle:@"Brightness\n\n" delegate:self cancelButtonTitle:@"Done" destructiveButtonTitle:nil otherButtonTitles: nil];
        [alert showInView:MSHookIvar<UIView*>([UISettingsToggleController sharedController], "toggleWindow")];
	CGRect frame = CGRectMake((alert.frame.size.height/2), 30.0, 200.0, 10.0);
	UISlider *slider = [[UISlider alloc] initWithFrame:frame];
	[slider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventValueChanged];
	[slider setBackgroundColor:[UIColor clearColor]];
	slider.minimumValue = 0.0f;
	slider.maximumValue = 1.0f;
	slider.continuous = YES;
	NSNumber *bl=nil;
	bl = (NSNumber*) CFPreferencesCopyAppValue(CFSTR("SBBacklightLevel2" ), CFSTR("com.apple.springboard"));
	slider.value = [bl floatValue];
	[alert addSubview:slider];
}
- (void)sliderAction:(UISlider*)arg1
{
	// SBBrightnessController on iOS5 has been fucked up.
	// _DETACH_THREAD(arg1);
	CFPreferencesSetAppValue(CFSTR("SBBacklightLevel2" ), [NSNumber numberWithFloat:[arg1 value]], CFSTR("com.apple.springboard"));
	GSEventSetBacklightLevel([arg1 value]);
}

-(void)respring
{
	exit(0);
}
-(void)wifi
{
	DETACH_THREAD
	id auto_z=[NSAutoreleasePool new];
	Class SBWiFiManager = objc_getClass("SBWiFiManager");
	BOOL wistatus=![[SBWiFiManager sharedInstance] wiFiEnabled];
	[[SBWiFiManager sharedInstance]setWiFiEnabled:wistatus];
	notify_post("com.qwerty.uisettings.reload");
	@try {
	[[SBWiFiManager sharedInstance] _askToJoinWithID:0];
	}
	@catch (id e){}
	[auto_z drain];
}
-(void)popupv
{
        Class UISettingsToggleController = objc_getClass("UISettingsToggleController");
        alert=[[UIActionSheet alloc] initWithTitle:@"Volume\n\n" delegate:self cancelButtonTitle:@"Done" destructiveButtonTitle:nil otherButtonTitles: nil];
	[alert showInView:MSHookIvar<UIView*>([UISettingsToggleController sharedController], "toggleWindow")];
	MPVolumeView *slider = [[[MPVolumeView alloc] initWithFrame:CGRectMake(60.0, 30.0, 200.0, 10.0)] autorelease];
	[slider sizeToFit];
	[alert addSubview:slider];
}
-(void)airplane
{
	DETACH_THREAD
	id auto_z=[NSAutoreleasePool new];
        BOOL airstatus=![[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] isInAirplaneMode];
	[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] setIsInAirplaneMode:airstatus];
	notify_post("com.qwerty.uisettings.reload");
	[auto_z drain];
}
-(void)shut
{
	[[objc_getClass("SpringBoard") sharedBoard] powerDown];
}
-(void)reboot
{
        [[objc_getClass("SpringBoard") sharedBoard] reboot];
}
-(void)bt
{
        Class BluetoothManager = objc_getClass("BluetoothManager");
        id btCont = [BluetoothManager sharedInstance];
        [btCont setPowered:![btCont powered]];
	notify_post("com.qwerty.uisettings.reload");
}
@end
%hook BluetoothManager
-(void)_powerChanged
{
%orig;
notify_post("com.qwerty.uisettings.reload");
}
%end
%ctor {
	UISettingsToggleController* handler=[objc_getClass("UISettingsToggleController") sharedController];
	wifi_on=[handler iconWithName:@"wifi.png"];
	wifi_off=[handler iconWithName:@"no_wifi.png"];
	airplane_on=[handler iconWithName:@"airplane.png"];
	airplane_on=[handler iconWithName:@"no_airplane.png"];
	bluetooth_on=[handler iconWithName:@"bluetooth.png"];
	bluetooth_off=[handler iconWithName:@"no_bluetooth.png"];
	id tcont=[UIToggleContr new];
        [handler createToggleWithTitle:@"Respring" andImage:@"respring.png" andSelector:@selector(respring) toTarget:tcont];
        wifi=[handler createToggleWithAction:@selector(wifi) title:nil target:tcont];
        [handler createLabelForButton:wifi text:@"WiFi"];
	airplane=[handler createToggleWithAction:@selector(airplane) title:nil target:tcont];
	[handler createLabelForButton:airplane text:@"Airplane"];
	bluetooth=[handler createToggleWithAction:@selector(bt) title:nil target:tcont];
	[handler createLabelForButton:bluetooth text:@"Bluetooth"];
	[handler createToggleWithTitle:@"Brightness" andImage:@"brightness.png" andSelector:@selector(popup) toTarget:tcont];
        [handler createToggleWithTitle:@"Volume" andImage:@"sound.png" andSelector:@selector(popupv) toTarget:tcont];
	[handler createToggleWithTitle:@"Power Off" andImage:@"shutoff.png" andSelector:@selector(shut) toTarget:tcont];
	[handler createToggleWithTitle:@"Reboot" andImage:@"reboot.png" andSelector:@selector(reboot) toTarget:tcont];
	[handler createToggleWithTitle:@"Safe Mode" andImage:@"safemode.png" andSelector:@selector(safemode) toTarget:tcont];
	CFNotificationCenterRef r = CFNotificationCenterGetDarwinNotifyCenter();
        CFNotificationCenterAddObserver(r, NULL, &refresh_, CFSTR("com.qwerty.uisettings.reload"), NULL, 0);
	refresh();
}

void refresh_(__CFNotificationCenter* b, void* c, const __CFString* d, const void* e, const __CFDictionary* a)
{
refresh();
}
void refresh()
{
        BOOL airstatus=[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] isInAirplaneMode];
        BOOL wistatus=[[objc_getClass("SBWiFiManager") sharedInstance] wiFiEnabled];
	BOOL btstatus=[[objc_getClass("BluetoothManager") sharedInstance] powered];
        if(wistatus){
                [wifi setImage:wifi_on forState:UIControlStateNormal];
        } else {
                [wifi setImage:wifi_off forState:UIControlStateNormal];
        }
        if(airstatus){
                [airplane setImage:airplane_on forState:UIControlStateNormal];
        } else {
                [airplane setImage:airplane_off forState:UIControlStateNormal];
        }
        if(btstatus){
                [bluetooth setImage:bluetooth_on forState:UIControlStateNormal];
        } else {
                [bluetooth setImage:bluetooth_off forState:UIControlStateNormal];
        }
	[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] airplaneModeChanged];
	[[objc_getClass("SBTelephonyManager") sharedTelephonyManagerCreatingIfNecessary:YES] updateAirplaneMode];
}

#import <libobjcipc/objcipc.h>
#import <UIKit/UIKit.h>

#define kOBJCIPCServer1 @"com.rabih96.Zeal.orientation1"
#define kOBJCIPCServer2 @"com.rabih96.Zeal.orientation2"

%hook UIApplication

- (id)init{
	[OBJCIPC registerIncomingMessageFromSpringBoardHandlerForMessageName:kOBJCIPCServer1 handler:^NSDictionary *(NSDictionary *message) {
		NSDictionary *return_message = @{
			@"currentOrientation" : [NSNumber numberWithLongLong:[[UIApplication sharedApplication] statusBarOrientation]],
		};
		return return_message;
	}];

	return %orig;
}

-(void)setStatusBarOrientation:(UIInterfaceOrientation)orientation animationParameters:(id)arg2 notifySpringBoardAndFence:(BOOL)arg3 updateBlock:(id)arg4 {
	[OBJCIPC sendMessageToSpringBoardWithMessageName:kOBJCIPCServer2 dictionary:@{ @"orientation": [NSNumber numberWithLongLong:orientation] } replyHandler:^(NSDictionary *response) {}];
	%orig;
}

%end

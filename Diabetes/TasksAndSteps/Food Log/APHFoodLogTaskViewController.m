// 
//  Food 
//  GlucoSuccess 
// 
// Copyright (c) 2015, Massachusetts General Hospital. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 
 
#import "APHFoodLogTaskViewController.h"

static NSString *kFoodLogStep       = @"FoodLogStep";
static NSString *kFoodLogStepLaunch = @"FoodLogStepLaunch";

@interface APHFoodLogTaskViewController ()

@end

@implementation APHFoodLogTaskViewController

+ (ORKOrderedTask *)createTask:(APCScheduledTask*) __unused scheduledTask
{
    ORKInstructionStep * step = [[ORKInstructionStep alloc] initWithIdentifier:kFoodLogStep];
    step.detailText = @"Log Food";
    
    ORKInstructionStep * stepLaunch = [[ORKInstructionStep alloc] initWithIdentifier:kFoodLogStepLaunch];
    stepLaunch.detailText = @"Lose It!";
    
    return  [[ORKOrderedTask alloc] initWithIdentifier:@"Log Food" steps:@[step, stepLaunch]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (ORKStepViewController *)taskViewController:(ORKTaskViewController *) __unused taskViewController viewControllerForStep:(ORKStep *)step
{
    APCStepViewController  *controller = nil;
    if ([step.identifier isEqualToString:kFoodLogStep]) {
        controller = (APCInstructionStepViewController*) [[UIStoryboard storyboardWithName:@"APCInstructionStep"
                                                                                    bundle:[NSBundle appleCoreBundle]] instantiateInitialViewController];
        
        APCInstructionStepViewController * instController = (APCInstructionStepViewController*) controller;
        
        instController.imagesArray = @[@"WhyLogFood", @"GetStarted", @"HealthPermissions", @"LoseIt"];
        instController.headingsArray = @[
                                         NSLocalizedString(@"Why Log Your Food?", @"Why Log Your Food?"),
                                         NSLocalizedString(@"Getting Started", @"Getting Started"),
                                         NSLocalizedString(@"Connect to Health App", @"Connect to Health App"),
                                         NSLocalizedString(@"What Now?", @"What Now?")
                                        ];
        instController.messagesArray = @[
                                         NSLocalizedString(@"Keeping a current food log allows you to understand your performance trend based on the foods you eat.",
                                                           @"Keeping a current food log allows you to understand your performance trend based on the foods you eat."),
                                         NSLocalizedString(@"You will be logging your food data via Lose It! A helpful food tracking resource from the App Store.",
                                                           @"You will be logging your food data via Lose It! A helpful food tracking resource from the App Store."),
                                         NSLocalizedString(@"As you log your first meal, Health app will ask for access to future entries. Tap Allow, to quickly sync data and produce the most accurate analysis.",
                                                           @"As you log your first meal, Health app will ask for access to future entries. Tap Allow, to quickly sync data and produce the most accurate analysis."),
                                         NSLocalizedString(@"Whenever  you want to log food data, return here and tap Get Started to launch Lose It! Remember to log often for best results.",
                                                           @"Whenever  you want to log food data, return here and tap Get Started to launch Lose It! Remember to log often for best results.")
                                         ];
        controller.delegate = self;
        controller.step = step;
        controller.title = NSLocalizedString(@"Log Food", @"Log Food");
    } else if ([step.identifier isEqualToString:kFoodLogStepLaunch]) {
        controller = [[UIStoryboard storyboardWithName:@"APHFoodLogLaunch" bundle:nil] instantiateInitialViewController];
        controller.delegate = self;
        controller.step = step;
    }
    
    return controller;
}

@end

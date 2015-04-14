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
 
#import "APHFoodLogLaunchViewController.h"

@interface APHFoodLogLaunchViewController ()

@property (nonatomic) BOOL isLoseItInstalled;
@property (nonatomic, strong) NSURL *loseItURLScheme;
@property (weak, nonatomic) IBOutlet UIButton *btnLoseIt;

@end

@implementation APHFoodLogLaunchViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIApplication *application = [UIApplication sharedApplication];
    NSDictionary *loseIdAppInfo = @{@"scheme": @"loseit", @"id": @"297368629"};
    NSString *scheme = [loseIdAppInfo objectForKey:@"scheme"];
    self.loseItURLScheme = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", scheme]];
    
    self.isLoseItInstalled = [application canOpenURL:self.loseItURLScheme];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.isLoseItInstalled) {
        [self.btnLoseIt setTitle:NSLocalizedString(@"Open Lose It!", @"Open Lose It!") forState:UIControlStateNormal];
    } else {
        [self.btnLoseIt setTitle:NSLocalizedString(@"Get Lose It!", @"Get Lose It!") forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)goGetLoseIt:(UIButton *) __unused sender
{
    if (self.isLoseItInstalled) {
        [[UIApplication sharedApplication] openURL:self.loseItURLScheme];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL
                                                    URLWithString:@"https://itunes.apple.com/us/app/lose-it!-weight-loss-program/id297368629?mt=8"]];
    }
    
    if ([self.delegate respondsToSelector:@selector(stepViewController:didFinishWithNavigationDirection:)] == YES) {
        [self.delegate stepViewController:self didFinishWithNavigationDirection:ORKStepViewControllerNavigationDirectionForward];
    }
}

@end

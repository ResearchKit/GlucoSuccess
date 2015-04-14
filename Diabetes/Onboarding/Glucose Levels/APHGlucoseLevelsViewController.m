// 
//  Glucose 
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
 
#import "APHGlucoseLevelsViewController.h"

static NSString *kGlucoseLevelCellIdentifier = @"GlucoseLevelCell";
static NSString *kGlucoseLevelAnswerKey      = @"GlucoseLevelAnswerKey";
static NSString *kGlucoseLevelIndexPathKey   = @"GlucoseLevelIndexPathKey";

const CGFloat kGlucoseLevelCellHeight = 65.0;

@interface APHGlucoseLevelsViewController ()

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;
@property (strong, nonatomic) NSString *sceneDataIdentifier;

@end

@implementation APHGlucoseLevelsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNavAppearance];
    
    self.sceneDataIdentifier = [NSString stringWithFormat:@"%@-%@", self.onboarding.currentStep.identifier, kGlucoseLevelCellIdentifier];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // check if there is data for the scene
    NSDictionary *sceneData = [self.onboarding.sceneData valueForKey:self.sceneDataIdentifier];
    
    if (sceneData) {
        self.selectedIndexPath = sceneData[kGlucoseLevelIndexPathKey];
        
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.selectedIndexPath) {
        [self.onboarding.sceneData setValue:@{
                                              kGlucoseLevelIndexPathKey: self.selectedIndexPath
                                              }
                                     forKey:self.sceneDataIdentifier];
    }

    [super viewWillDisappear: animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (APCOnboarding *)onboarding
{
    return ((APCAppDelegate *)[UIApplication sharedApplication].delegate).onboarding;
}

- (void)setupNavAppearance
{
    UIBarButtonItem *backBarButton = [APCCustomBackButton customBackBarButtonItemWithTarget:self
                                                                                     action:@selector(goBackwards)
                                                                                  tintColor:[UIColor appPrimaryColor]];
    [self.navigationItem setLeftBarButtonItem:backBarButton];
    
}

#pragma mark - Navigation

- (void)goBackwards
{
    [self.navigationController popViewControllerAnimated:YES];
    [[self onboarding] popScene];
}

- (IBAction)goForward:(UIBarButtonItem *) __unused sender
{
    if (self.selectedIndexPath.row == 0) {
        [self performSegueWithIdentifier:@"SegueToSelectingDays" sender:nil];
    } else {
        UIViewController *viewController = [[self onboarding] nextScene];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark - TableView
#pragma mark Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *) __unused tableView numberOfRowsInSection:(NSInteger) __unused section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGlucoseLevelCellIdentifier
                                                            forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = NSLocalizedString(@"Yes", @"Yes");
    } else {
        cell.textLabel.text = NSLocalizedString(@"No", @"No");
    }
    
    if (self.selectedIndexPath && (self.selectedIndexPath.row == indexPath.row)) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = [UIColor appPrimaryColor];
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *) __unused tableView heightForRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    return kGlucoseLevelCellHeight;
}

#pragma mark Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedIndexPath = indexPath;
    
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    [tableView reloadData];
}


@end

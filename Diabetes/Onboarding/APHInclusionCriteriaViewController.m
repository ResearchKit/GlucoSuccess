// 
//  APHInclusionCriteriaViewController.m 
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
 


#import "APHInclusionCriteriaViewController.h"
#import "APHAppDelegate.h"

@interface APHInclusionCriteriaViewController () <APCSegmentedButtonDelegate>

//Outlets
@property (weak, nonatomic) IBOutlet UILabel *question1Label;
@property (weak, nonatomic) IBOutlet UIButton *question1Option1;
@property (weak, nonatomic) IBOutlet UIButton *question1Option2;

@property (weak, nonatomic) IBOutlet UILabel *question2Label;
@property (weak, nonatomic) IBOutlet UIButton *question2Option1;
@property (weak, nonatomic) IBOutlet UIButton *question2Option2;

@property (weak, nonatomic) IBOutlet UILabel *question3Label;
@property (weak, nonatomic) IBOutlet UIButton *question3Option1;
@property (weak, nonatomic) IBOutlet UIButton *question3Option2;

@property (weak, nonatomic) IBOutlet UILabel *question4Label;
@property (weak, nonatomic) IBOutlet UIButton *question4Option1;
@property (weak, nonatomic) IBOutlet UIButton *question4Option2;


//Properties
@property (nonatomic, strong) NSArray * questions; //Of APCSegmentedButtons

@end

@implementation APHInclusionCriteriaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.questions = @[
                       [[APCSegmentedButton alloc] initWithButtons:@[self.question1Option1, self.question1Option2] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]],
                       [[APCSegmentedButton alloc] initWithButtons:@[self.question2Option1, self.question2Option2] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]],
                       [[APCSegmentedButton alloc] initWithButtons:@[self.question3Option1, self.question3Option2] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]],
                       [[APCSegmentedButton alloc] initWithButtons:@[self.question4Option1, self.question4Option2] normalColor:[UIColor appSecondaryColor3] highlightColor:[UIColor appPrimaryColor]],
                       ];
    [self.questions enumerateObjectsUsingBlock:^(APCSegmentedButton * obj, NSUInteger __unused idx, BOOL * __unused stop) {
        obj.delegate = self;
    }];
    [self setUpAppearance];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) setUpAppearance
{
    {
        self.question1Label.textColor = [UIColor appSecondaryColor1];
        self.question1Label.font = [UIFont appQuestionLabelFont];
        
        [self.question1Option1.titleLabel setFont:[UIFont appQuestionOptionFont]];
        [self.question1Option2.titleLabel setFont:[UIFont appQuestionOptionFont]];
    }
    
    {
        self.question2Label.textColor = [UIColor appSecondaryColor1];
        self.question2Label.font = [UIFont appQuestionLabelFont];
        
        [self.question2Option1.titleLabel setFont:[UIFont appQuestionOptionFont]];
        [self.question2Option2.titleLabel setFont:[UIFont appQuestionOptionFont]];
    }
    
    {
        self.question3Label.textColor = [UIColor appSecondaryColor1];
        self.question3Label.font = [UIFont appQuestionLabelFont];
        
        [self.question3Option1.titleLabel setFont:[UIFont appQuestionOptionFont]];
        [self.question3Option2.titleLabel setFont:[UIFont appQuestionOptionFont]];
    }
    
    {
        self.question4Label.textColor = [UIColor appSecondaryColor1];
        self.question4Label.font = [UIFont appQuestionLabelFont];
        
        [self.question4Option1.titleLabel setFont:[UIFont appQuestionOptionFont]];
        [self.question4Option2.titleLabel setFont:[UIFont appQuestionOptionFont]];
    }
    
}

- (APCOnboarding *)onboarding
{
    return ((APHAppDelegate *)[UIApplication sharedApplication].delegate).onboarding;
}

/*********************************************************************************/
#pragma mark - Misc Fix
/*********************************************************************************/
-(void)viewDidLayoutSubviews
{
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
}

-(void)tableView:(UITableView *) __unused tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

/*********************************************************************************/
#pragma mark - Segmented Button Delegate
/*********************************************************************************/
- (void)segmentedButtonPressed:(UIButton *) __unused button selectedIndex:(NSInteger) __unused selectedIndex
{
    self.navigationItem.rightBarButtonItem.enabled = [self isContentValid];
    
}

/*********************************************************************************/
#pragma mark - Overridden methods
/*********************************************************************************/

- (void)next
{
    [self onboarding].onboardingTask.eligible = [self isEligible];
    
    UIViewController *viewController = [[self onboarding] nextScene];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (BOOL) isEligible
{
    BOOL retValue = YES;
    
    APCSegmentedButton * question1 = self.questions[0];
    APCSegmentedButton * question2 = self.questions[1];
    APCSegmentedButton * question3 = self.questions[2];
    APCSegmentedButton * question4 = self.questions[3];
    
    if ((question1.selectedIndex == 1) ||
        (question2.selectedIndex == 1) ||
        (question3.selectedIndex == 1) ||
        (question4.selectedIndex == 1)) {
        retValue = NO;
    }
    return retValue;
}

- (BOOL)isContentValid
{
    __block BOOL retValue = YES;
    [self.questions enumerateObjectsUsingBlock:^(APCSegmentedButton* obj, NSUInteger __unused idx, BOOL *stop) {
    if (obj.selectedIndex == -1) {
        retValue = NO;
        *stop = YES;
    }
    }];
    return retValue;
}

@end

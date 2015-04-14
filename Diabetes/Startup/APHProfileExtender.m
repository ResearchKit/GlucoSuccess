// 
//  APHProfileExtender.m 
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
 
#import "APHProfileExtender.h"
#import "APHGlucoseLevelsMealTimesViewController.h"

static  NSInteger  kDefaultNumberOfExtraSections = 2;

@implementation APHProfileExtender

- (instancetype) init {
    self = [super init];

    if (self) {
        
    }
    
    return self;
}

- (BOOL)willDisplayCell:(NSIndexPath *) __unused indexPath {
    return YES;
}

//This is all the content (rows, sections) that is prepared at the appCore level
/*
- (NSArray *)preparedContent:(NSArray *)array {
    return array;
}
*/

/**
  * @returns kDefaultNumberOfExtraSections extra sections for a nicer layout in profile
  *
  * @note    To turn off the feature in the profile View Controller, return  0.
  */
- (NSInteger)numberOfSectionsInTableView:(UITableView *) __unused tableView
{
    return  kDefaultNumberOfExtraSections;
}

//
//    Add to the number of rows
//
- (NSInteger) tableView:(UITableView *) __unused tableView numberOfRowsInAdjustedSection:(NSInteger)section
{
    NSInteger count = 0;
    
    if (section == 0) {
        count = 1;
    }
    
    return count;
}

/**
  * @returns  A default style Table View Cell unless you have special requirements
  */
- (UITableViewCell *)cellForRowAtAdjustedIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"GlucoseLogSetup"];
        cell.textLabel.text = NSLocalizedString(@"Glucose Log", @"Glucose Log");
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtAdjustedIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat height = tableView.rowHeight;
    
    if (indexPath.section == 0) {
        height = 65.0;
    }
    
    return height;
}

/**
  * @brief
  *
  * @note   Provide a sub-class of UIViewController to do the work.
  *         You can either push the controller or present it, depending on your preferences.
  */
- (void)navigationController:(UINavigationController *)navigationController didSelectRowAtIndexPath:(NSIndexPath *) __unused indexPath
{
    UIStoryboard *sbGlucoseLog = [UIStoryboard storyboardWithName:@"APHOnboarding" bundle:[NSBundle mainBundle]];
    APHGlucoseLevelsMealTimesViewController *controller = [sbGlucoseLog instantiateViewControllerWithIdentifier:@"APHGlucoseMealTimes"];
    
    controller.navigationController.navigationBar.topItem.title = NSLocalizedString(@"Glucose Log", @"");
    controller.hidesBottomBarWhenPushed = YES;
    
    controller.isConfigureMode = YES;
    
    [navigationController pushViewController:controller animated:YES];
}

@end

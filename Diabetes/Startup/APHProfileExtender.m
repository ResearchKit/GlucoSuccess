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
#import <MessageUI/MFMailComposeViewController.h>

NSString * const kFeedbackEmailAddress = @"glucosuccess.feedback@gmail.com";

static  NSInteger  kDefaultNumberOfExtraSections = 2;

typedef NS_ENUM(NSUInteger, APHProfileSections)
{
    APHProfileSectionGlucoseLog = 0,
    APHProfileSectionFeedback
};

@interface APHProfileExtender() <MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *profileCellsDatasource;
@property (nonatomic, weak) UINavigationController *weakNavController;

@end

@implementation APHProfileExtender

- (instancetype) init {
    self = [super init];

    if (self) {
        _profileCellsDatasource = @[NSLocalizedString(@"Glucose Log", nil), NSLocalizedString(@"Send Your Feedback", nil)];
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
        count = self.profileCellsDatasource.count;
    }
    
    return count;
}

- (UITableViewCell *)decorateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)__unused indexPath
{
    
    cell.textLabel.text = [self.profileCellsDatasource objectAtIndex:indexPath.row];
    cell.detailTextLabel.text = @"";
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    if (indexPath.row == APHProfileSectionGlucoseLog) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
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
    UIViewController *controller = nil;
    
    switch (indexPath.row) {
        case APHProfileSectionGlucoseLog:
        {
            UIStoryboard *sbGlucoseLog = [UIStoryboard storyboardWithName:@"APHOnboarding" bundle:[NSBundle mainBundle]];
            APHGlucoseLevelsMealTimesViewController *glucoseController = [sbGlucoseLog instantiateViewControllerWithIdentifier:@"APHGlucoseMealTimes"];
            
            glucoseController.navigationController.navigationBar.topItem.title = NSLocalizedString(@"Glucose Log", @"");
            glucoseController.hidesBottomBarWhenPushed = YES;
            
            glucoseController.isConfigureMode = YES;
            
            controller = glucoseController;
            
            [navigationController pushViewController:controller animated:YES];
        }
            break;
            
        default:
        {
            MFMailComposeViewController *feedbackController = [self feedback];
            
            self.weakNavController = navigationController;
            
            if (feedbackController) {
                controller = feedbackController;
                
                [navigationController presentViewController:controller animated:YES completion:nil];
            } else {
                NSString *addEmailAccountMessage = NSLocalizedString(@"You don't have any email accounts set up. Please add an email account in Settings -> Mail, Contacts, Calendars", nil);
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Email Accounts", nil)
                                                                                   message:addEmailAccountMessage
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction * __unused action) {}];
                
                [alertView addAction:defaultAction];
                
                [self.weakNavController presentViewController:alertView animated:YES completion:nil];
            }
        }
            break;
    }
    
    [self.profileViewController.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (MFMailComposeViewController *)feedback
{
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    
    NSString *appInfo = [NSString stringWithFormat:@"%@\n%@", [APCUtilities appName], [APCUtilities appVersion]];
    NSString *hardware = [APCDeviceHardware platformString];
    NSString *subject = NSLocalizedString(@"Feedback", nil);
    [mailComposer setToRecipients:[NSArray arrayWithObjects:kFeedbackEmailAddress, nil]];
    [mailComposer setSubject:[NSString stringWithFormat:@"%@", subject]];
    [mailComposer setMessageBody:[NSString stringWithFormat:@"\n\nPlease do not enclose any sensitive information when emailing glucosuccess.feedback@gmail.com\n\n---\n%@\n%@", appInfo, hardware] isHTML:NO];
    
    return mailComposer;
}

- (void)mailComposeController:(MFMailComposeViewController*) __unused controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            APCLogDebug(@"Feedback was canceled");
            break;
        case MFMailComposeResultSaved:
            APCLogDebug(@"Feedback was saved as draft.");
            break;
        case MFMailComposeResultSent:
            APCLogDebug(@"Feedback has been sent.");
            break;
        case MFMailComposeResultFailed:
            APCLogError2(error);
            break;
        default:
            APCLogDebug(@"Feedback was not sent.");
            break;
    }
    
    [self.weakNavController dismissViewControllerAnimated:YES completion:nil];
}

@end

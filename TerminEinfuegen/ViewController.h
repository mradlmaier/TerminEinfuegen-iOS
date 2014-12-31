//
//  ViewController.h
//  TerminEinfuegen
//
//  Created by Michael Radlmaier on 30/12/14.
//  Copyright (c) 2014 Michael Radlmaier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
@import EventKitUI;

@interface ViewController : UIViewController <UITextFieldDelegate, EKCalendarChooserDelegate>
- (IBAction)insertEvent:(id)sender;
@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UITextField *titelTextField;
@property (strong, nonatomic) IBOutlet UIButton *createEventButton;
- (IBAction)chooseCalendar:(id)sender;
@end


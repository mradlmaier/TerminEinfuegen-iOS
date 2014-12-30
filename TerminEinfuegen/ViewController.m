//
//  ViewController.m
//  TerminEinfuegen
//
//  Created by Michael Radlmaier on 30/12/14.
//  Copyright (c) 2014 Michael Radlmaier. All rights reserved.
//

#import "ViewController.h"
#import <EventKit/EventKit.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self checkEventStoreAccessForEvents];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ACCESS FOR EVENTS

// teste Authorisation Status
-(void)checkEventStoreAccessForEvents
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    
    switch (status)
    {
            // Update our UI if the user has granted access to their Calendar
        case EKAuthorizationStatusAuthorized: [self accessGrantedForEvent];
            break;
            // Prompt the user for access to Calendar if there is no definitive answer
        case EKAuthorizationStatusNotDetermined: [self requestEventAccess];
            break;
            // Display a message if the user has denied or restricted access to Calendar
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Privatsphäre Warnung" message:@"Erlaubnis für Ereignisse nicht erhalten. Bitte erteilen Sie Zugriffserlaubnis in den Systemeinstellungen Ihres Gerätes: --> Einstellungen --> Datenschutz --> Ereignisse --> TerminEinfügen."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
            
            break;
        default:
            break;
    }
}


// Prompt den Benutzer für Zugriff auf Kalender
-(void)requestEventAccess
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error)
     {
         if (granted)
         {
             ViewController * __weak weakSelf = self;
             // Let's ensure that our code will be executed from the main queue
             dispatch_async(dispatch_get_main_queue(), ^{
                 // The user has granted access to their Calendar
                 [weakSelf accessGrantedForEvent];
             });
         }
     }];
}


// Diese Methode wird aufgerufen wenn der Benutzer Zugriff auf die Kalendar erlaubt
-(void)accessGrantedForEvent
{
    NSLog(@"Zugriff erlaubt...");
    
}

- (IBAction)insertEvent:(id)sender {
    // initialisiere EventStore
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    // hol den default calendar; man könnte stattdessen andere Kalendaer holen oder eigenen erstellen...
    EKCalendar *defaultCalendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
    EKSource *source = [[eventStore defaultCalendarForNewEvents] source];
    [defaultCalendar setSource:source];
    // erstelle event
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    // setze den Kalender für diese Event
    [event setCalendar:defaultCalendar];
    // setze Beginn und Ende
    event.startDate = self.datePicker.date;
    event.endDate = [NSDate dateWithTimeInterval:60*60 sinceDate:self.datePicker.date];
    // setze Titel und Beschreibung
    event.title = @"Mein Termin";
    [event setNotes:@"Lore ipsum..."];
    // setze Alarm
    [event addAlarm:[EKAlarm alarmWithRelativeOffset:60 * -60.0 * 24]];
    [event addAlarm:[EKAlarm alarmWithRelativeOffset:60 * -15.0]];
    // setze Wiederholung
    EKRecurrenceEnd *end = [EKRecurrenceEnd recurrenceEndWithEndDate:[NSDate dateWithTimeInterval:60*60*24*365 sinceDate:self.datePicker.date]];
    EKRecurrenceRule *rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:2 end:end];
    [event addRecurrenceRule:rule];
    NSLog(@"event: %@", event);
    // speichere event, man sollte ordenliches error handling implementieren...
    NSError *error;
    [eventStore saveEvent:event span:EKSpanFutureEvents error:&error];
    NSLog(@"error: %@", error);
}
@end

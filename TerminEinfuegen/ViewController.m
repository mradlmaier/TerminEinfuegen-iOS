//
//  ViewController.m
//  TerminEinfuegen
//
//  Created by Michael Radlmaier on 30/12/14.
//  Copyright (c) 2014 Michael Radlmaier. All rights reserved.
//
// Dies demonstriert wie ein Event in iOS 7 oder höher in eine Kalender geschrieben werden kann.
// ZU beachten:
// 1. Testen dass wir Zugriff auf den Kalender haben, wenn nicht, ist der "Event einfügen"-Button disabled
//    (Wenn der Benutzer in den Einstellungen nachträglich den Zugriff erlaubt/verbietet wird die automatisch neugestartet.
//    Deshalb ist immer sichergestellt, dass die App aus dem Hintergrund kommt, wenn der Benutzer diese Einstellungen)
// 2. Wir kreieren einen eigenen Kalender für diese App, damit ist sichergestellt, dass
//    a) der Kalender schreibbar ist.
//    b) wir nicht die Kalender des Benutzer durcheinander bringen (Dies weicht von den meisten Code-Samples im Internet ab, die in diesem
//       Punkt inkorrekt vorgehen, in dem das sie alle Kalender wahllos nach einem schreibbaren durchsuchen!).

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.titelTextField.delegate = self;
    [self hideKeyboardWhenBackgroundIsTapped];
    // Teste, ob wir Zugriff auf die Kalender haben
    [self checkEventStoreAccessForEvents];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TEXTFIELD

-(void)hideKeyboardWhenBackgroundIsTapped{
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [tgr setCancelsTouchesInView:NO];
    [self.view addGestureRecognizer:tgr];
}

-(void)hideKeyboard{
    [self.view endEditing:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField setUserInteractionEnabled:YES];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - ACCESS FOR EVENTS

// teste Authorisation Status
-(void)checkEventStoreAccessForEvents
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    
    switch (status)
    {
        case EKAuthorizationStatusAuthorized:
            // UI aktualisieren und Kalender kreieren, falls wir Zugriff erhalten haben
            [self accessGrantedForEvent];
            break;
        case EKAuthorizationStatusNotDetermined:
            // Benutzer fragen, da Status ungeklärt
            [self requestEventAccess];
            break;
        case EKAuthorizationStatusDenied:
        case EKAuthorizationStatusRestricted:
        {
            // Benutzer informieren, dass wir Zugriff auf Kalender brauchen
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
             // Code im UIThread/Mainthread exekutieren
             dispatch_async(dispatch_get_main_queue(), ^{
                 // Zugriff erlaubt
                 [weakSelf accessGrantedForEvent];
             });
         }
     }];
}


// Diese Methode wird aufgerufen wenn der Benutzer Zugriff erlaubt
-(void)accessGrantedForEvent
{
    NSLog(@"Zugriff erlaubt...");
    // eigenen Kalender erstellen, was garantiert, dass wir Schreibzugriff haben,
    // Außerdem hat dann unsere App Ihren eigenen Kalender, und wir bringen nicht die Kalender
    // des Benutzers durcheinander
    self.kalender = [self createLocalCalendarForMyEventsWithTitle:@"Mein Kalender"];
    [self.createEventButton setEnabled:YES];
    
}

- (IBAction)insertEvent:(id)sender {
    if ([self.titelTextField.text isEqualToString:@("")]) {
        // kein Titel, zeige Alert, dass Titel eingegeben werden muss, und abbrechen
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Titel fehlt!"
                                                          message:@"Bitte Titel eingeben."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        return;
    }
    // initialisiere EventStore
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    // eigenen Kalendar für Events kreieren, weil so sichergestellt ist das der Kalender schreibbar ist
    // erstelle event
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    // setze den Kalender für diese Event
    [event setCalendar:self.kalender];
    // setze Beginn und Ende
    event.startDate = self.datePicker.date;
    event.endDate = [NSDate dateWithTimeInterval:60*60 sinceDate:self.datePicker.date];
    // setze Titel und Beschreibung
    event.title = self.titelTextField.text;
    [event setNotes:@"Lore ipsum..."];
    // setze Alarm
    [event addAlarm:[EKAlarm alarmWithRelativeOffset:60 * -60.0 * 24]];
    [event addAlarm:[EKAlarm alarmWithRelativeOffset:60 * -15.0]];
    // setze Wiederholung
    EKRecurrenceEnd *end = [EKRecurrenceEnd recurrenceEndWithEndDate:[NSDate dateWithTimeInterval:60*60*24*365 sinceDate:self.datePicker.date]];
    EKRecurrenceRule *rule = [[EKRecurrenceRule alloc] initRecurrenceWithFrequency:EKRecurrenceFrequencyWeekly interval:2 end:end];
    [event addRecurrenceRule:rule];
    NSLog(@"event: %@", event);
    // TODO implementiere error handling
    NSError *error;
    [eventStore saveEvent:event span:EKSpanFutureEvents error:&error];
    NSLog(@"error: %@", error);
}



-(EKCalendar *)createLocalCalendarForMyEventsWithTitle:(NSString *)title{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    
    EKSource *theSource = [[eventStore defaultCalendarForNewEvents] source];
    EKCalendar *calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:eventStore];
    calendar.title = title;
    calendar.source = theSource;
    
    NSError *error;
    [eventStore saveCalendar:calendar commit:YES error:&error];
    // TODO implementiere error handling
    return calendar;
}
@end

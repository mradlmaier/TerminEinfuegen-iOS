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
    [self.createEventButton setEnabled:YES];
    [self.createEventAndChooseCalButton setEnabled:YES];
    [self.createEventWithiOSUIButton setEnabled:YES];
    
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
    // initialisiere event
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    // kreierten Kalender suchen oder eigenen Kalendar für Events kreieren, weil so sichergestellt ist das der Kalender schreibbar ist
    EKCalendar *kalender = [self getCalendarForEventsWithTitle:@"Mein Kalender"];
    if(!kalender){
        kalender = [self createLocalCalendarForMyEventsWithTitle:@"Mein Kalender"];
    }
    if(!kalender){
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Kein Kalender"
                                                          message:@"Kein Kalender konnte gefunden noch kreiert werden."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        return;
    }
    // setze den Kalender für diese Event
    [event setCalendar:kalender];
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
    if (error) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                          message:error.localizedDescription
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
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

-(EKCalendar *)getCalendarForEventsWithTitle:(NSString *)title{
    // es wäre schön wenn wir den Kalender an einem eindeutigerem Attribut suchen könnten als den Titel
    // (den der Benutzer allerdings ändern könnte), aber die Property calendarIdentifier überlebt einen Sync nicht...
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    NSArray *calendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
    for (EKCalendar* cal in calendars){
        if ([cal.title isEqualToString:title]) {
            if(cal.allowsContentModifications){
                return cal;
            }
        }
    }
    return nil;
}
#pragma mark - EKCalendarChooserDelegate
- (void)calendarChooserSelectionDidChange:(EKCalendarChooser *)calendarChooser{
    NSLog(@"calendarChooserSelectionDidChange: %@", calendarChooser.selectedCalendars);
    // Calendar wurde gewählt, speichere für später
    NSArray *calendars = [calendarChooser.selectedCalendars allObjects];
    self.selectedCalendar = [calendars firstObject];
}

- (void)calendarChooserDidFinish:(EKCalendarChooser *)calendarChooser{
    NSLog(@"calendarChooserDidFinish: %@", calendarChooser.selectedCalendars);
}

- (void)calendarChooserDidCancel:(EKCalendarChooser *)calendarChooser{
    NSLog(@"calendarChooserDidCancel: %@", calendarChooser.selectedCalendars);
}

- (IBAction)chooseCalendar:(id)sender {
    // this präsentiert den EKCalendarChooser modal, so dass der Benutzer einen schreibbaren Kalender wählen kann
    EKEventStore *store = [[EKEventStore alloc] init];
    EKCalendarChooser *chooser = [[EKCalendarChooser alloc] initWithSelectionStyle:EKCalendarChooserSelectionStyleSingle displayStyle:EKCalendarChooserDisplayWritableCalendarsOnly entityType:EKEntityTypeEvent eventStore:store];
    chooser.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chooser];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Abbrechen"
                                   style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(cancel:)];
    chooser.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Fertig"
                                     style:UIBarButtonItemStyleDone
                                     target:self
                                     action:@selector(done:)];
    chooser.navigationItem.rightBarButtonItem = doneButton;
    
    [[self navigationController] presentViewController:navController animated:YES completion:nil];
}

-(IBAction)cancel:(id)sender{
    NSLog(@"cancel");
    // EKCalendarChooser schließen
    [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
    self.selectedCalendar = nil;
}

-(IBAction)done:(id)sender{
    NSLog(@"done");
    // teste, ob ein Kalender gewählt wurde
    if (!self.selectedCalendar) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Kein Kalender gewählt"
                                                          message:@"Bitte wähle einen Kalender"
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        return;
    }
    // ein Kalender ist gewählt, wir können den Termin einfügen, und den EKCalendarChooser schließen
    //--------------------------
    // initialisiere EventStore
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    // initialisiere event
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    // setze den Kalender für diese Event
    [event setCalendar:self.selectedCalendar];
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
    if (error) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                          message:error.localizedDescription
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
    // EKCalendarChooser schließen
    [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
    self.selectedCalendar = nil;
}

- (IBAction)createEventWithiOSUI:(id)sender {
    // Das ist die einfachste Möglichkeit, mittels EKEventEditViewController, und deren Delegates
    //
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
    // wir können einige Details vor-ausfüllen
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
    
    // initialisiere EKEventEditViewController
    EKEventEditViewController *addController = [[EKEventEditViewController alloc] initWithNibName:nil bundle:nil];
    addController.eventStore = eventStore;
    addController.event = event;
    
    
    
    [self presentViewController:addController animated:YES completion:nil];
    addController.editViewDelegate = self;
}

#pragma mark - EKEventEditViewDelegate
- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action{
    ViewController * __weak weakSelf = self;
    // Dismiss the modal view controller
    [self dismissViewControllerAnimated:YES completion:^
     {
         if (action != EKEventEditViewActionCanceled)
         {
             // das Event wurde schon gespeichert, wir können aber irgendetwas tun mit dem Event, falls nötig
             EKEvent *event = controller.event;
             NSLog(@"event: %@", event);
             NSLog(@"eventIdentifier: %@", event.eventIdentifier);
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 // aktualisiere UI
             });
         } else {
            // mach was, falls der Benutzer die Erstellung des Termins abgebrochen hat
         }
     }];
}
@end

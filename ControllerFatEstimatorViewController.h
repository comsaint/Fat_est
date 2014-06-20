//
//  ControllerFatEstimatorViewController.h
//  Fat_Estimation
//
//  Created by Long Pun on 23/08/13.
//
//

#import <Cocoa/Cocoa.h>

@interface ControllerFatEstimatorViewController : NSViewController

@end

//
//  FatEstimator.h
//  Fat_Estimation
//
//  Created by Long Pun on 23/08/13.
//
//

#import <AppKit/AppKit.h>

@class Fat_EstimationFilter;

@interface ControllerFatEstimator : NSWindowController
{
    IBOutlet NSTextField *total_area;
    IBOutlet NSTextField *rmean,*rvar,*rskew;
    IBOutlet NSTextField *fcsa_otsu,*muscle_area_otsu,*fat_content_otsu,*fat_area_otsu;
    IBOutlet NSTextField *fcsa_met,*muscle_area_met,*fat_content_met,*fat_area_met;
    
    IBOutlet NSWindow *fillWindow;
    
    Fat_EstimationFilter *filter;
    ROI *curROI;
}

- (id) init: (Fat_EstimationFilter*) f;
- (IBAction)compute:(id)sender;//compute fsca,etc
- (ViewerController*) viewerController;

@end

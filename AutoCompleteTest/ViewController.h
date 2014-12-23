//
//  ViewController.h
//  AutoCompleteTest
//
//  Created by PiHan Hsu on 2014/11/28.
//  Copyright (c) 2014年 PiHan Hsu. All rights reserved.
//


#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>
#import "SPGooglePlacesAutocomplete.h"

@interface ViewController : UIViewController
{
    NSArray *searchResultPlaces;
    SPGooglePlacesAutocompleteQuery *searchQuery;
    //MKPointAnnotation *selectedPlaceAnnotation;
    
    BOOL shouldBeginEditing;

}


@end


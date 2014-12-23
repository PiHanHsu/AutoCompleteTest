//
//  ViewController.m
//  AutoCompleteTest
//
//  Created by PiHan Hsu on 2014/11/28.
//  Copyright (c) 2014年 PiHan Hsu. All rights reserved.
//

#import "ViewController.h"
#import <GoogleMaps/GoogleMaps.h>
#import "AddItemView.h"
#define API_KEY @"AIzaSyAFsaDn7vyI8pS53zBgYRxu0HfRwYqH-9E"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, GMSMapViewDelegate>
{
    GMSMapView * mapView;
    
}
@property UIView * addItemView;
@property (strong, nonatomic) NSMutableString * placeDetailURL;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    searchQuery = [[SPGooglePlacesAutocompleteQuery alloc] initWithApiKey:@"AIzaSyAFsaDn7vyI8pS53zBgYRxu0HfRwYqH-9E"];
    shouldBeginEditing = YES;
    
    // Do any additional setup after loading the view, typically from a nib.
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:25.023868
                                                            longitude:121.528976
                                                                 zoom:15];
    mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height);
    mapView.myLocationEnabled = YES;
    mapView.delegate = self;
    self.searchDisplayController.searchBar.placeholder =@"Search";

    
    [self.view insertSubview:mapView atIndex:0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSLog(@"searchResult: %@", searchResultPlaces);
    NSLog(@"search count: %lu", searchResultPlaces.count);
    return [searchResultPlaces count];
    
    
}

- (SPGooglePlacesAutocompletePlace *)placeAtIndexPath:(NSIndexPath *)indexPath {
    return searchResultPlaces[indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"SPGooglePlacesAutocompleteCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"GillSans" size:16.0];
    cell.textLabel.text = [self placeAtIndexPath:indexPath].name;
    return cell;
}




#pragma mark -
#pragma mark UITableViewDelegate

- (void)recenterMapToPlacemark:(CLPlacemark *)placemark {
//    MKCoordinateRegion region;
//    MKCoordinateSpan span;
//    
//    span.latitudeDelta = 0.02;
//    span.longitudeDelta = 0.02;
//    
//    region.span = span;
//    region.center = placemark.location.coordinate;
//    
//    NSLog(@"region.span: %@", span);
//    NSLog(@"region.center: %@", placemark.location.coordinate);
//    [self.mapView setRegion:region];


    // still can't update the new place to what we tap on the search result.
    CGPoint point = [mapView.projection pointForCoordinate:placemark.location.coordinate];
    GMSCameraUpdate *camera =
    [GMSCameraUpdate setTarget:[mapView.projection coordinateForPoint:point]];
    [mapView animateWithCameraUpdate:camera];
    
}

//- (void)addPlacemarkAnnotationToMap:(CLPlacemark *)placemark addressString:(NSString *)address {
//    [self.mapView removeAnnotation:selectedPlaceAnnotation];
//    
//    selectedPlaceAnnotation = [[MKPointAnnotation alloc] init];
//    selectedPlaceAnnotation.coordinate = placemark.location.coordinate;
//    selectedPlaceAnnotation.title = address;
//    [self.mapView addAnnotation:selectedPlaceAnnotation];
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SPGooglePlacesAutocompletePlace *place = [self placeAtIndexPath:indexPath];
    [place resolveToPlacemark:^(CLPlacemark *placemark, NSString *addressString, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not map selected Place"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else if (placemark) {
            //[self addPlacemarkAnnotationToMap:placemark addressString:addressString];
            [self recenterMapToPlacemark:placemark];
//            [self.searchDisplayController setActive:NO];
//            [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:indexPath animated:NO];
            
           
            
            
            self.placeDetailURL = [NSMutableString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/details/json?reference=%@&sensor=ture&key=%@",
                                    place.reference, API_KEY];
            [self runURLRequest];
            
        }
    }];
}

- (void)runURLRequest {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.placeDetailURL] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    
    [NSURLConnection sendAsynchronousRequest:mutableRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSError *error = nil;
        if (data) {
            NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (!error) {
                NSDictionary *resultsDict = [jsonDictionary objectForKey:@"result"];
                NSDictionary * geometryDict = [resultsDict objectForKey:@"geometry"];
                NSString *name = [resultsDict objectForKey:@"name"];
                NSString *address = [resultsDict objectForKey:@"formatted_address"]
                ;
                NSString * tel = [resultsDict objectForKey:@"formatted_phone_number"];
                AddItemView *itemView =  [[[NSBundle mainBundle] loadNibNamed:@"AddItemView" owner:self options:nil] objectAtIndex:0];
                
                self.addItemView = itemView;
                self.addItemView.center = self.view.center;
                self.addItemView.layer.cornerRadius =10.f;
                self.addItemView.layer.masksToBounds =YES;
                
                itemView.nameTextField.text=name;
                itemView.addressTextField.text=address;
                itemView.telTextField.text=tel;
                
                [self.view addSubview:self.addItemView];
                 [itemView.addButton addTarget:self action:@selector(ViewDismiss:) forControlEvents:UIControlEventTouchUpInside];

            } else {
                NSLog(@"Error with: %@", error);
            }
        }
        
    }];
    
}



-(void)ViewDismiss:(id)sender{
    
    [self.addItemView removeFromSuperview];
    
}


#pragma mark -
#pragma mark UISearchDisplayDelegate

- (void)handleSearchForSearchString:(NSString *)searchString {
    searchQuery.location = mapView.myLocation.coordinate;
    searchQuery.input = searchString;
    [searchQuery fetchPlaces:^(NSArray *places, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not fetch Places"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
            [alert show];
        } else {
            searchResultPlaces = places;
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self handleSearchForSearchString:searchString];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}



@end

//
//  AMMapGridLayer.m
//  Astrometry
//
//  Created by Don Willems on 27/11/14.
//  Copyright (c) 2014 lapsedpacifist. All rights reserved.
//

#import "AMMapGridLayer.h"
#import "AMSphericalCoordinates.h"
#import "AMScalarMeasure.h"
#import "AMQuantity.h"
#import "AMUnit.h"
#import "AMCoordinateSystem.h"
#import "AMPlot.h"
#import "AMAstrometricMap.h"
#import "AMAstrometricMap.h"
#import "AMCoordinateSystem.h"

NSString *const AMMapGridLayerChangedMajorGridLinePropertiesNotification = @"AMMapGridLayerChangedMajorGridLinePropertiesNotification";
NSString *const AMMapGridLayerChangedMinorGridLinePropertiesNotification = @"AMMapGridLayerChangedMinorGridLinePropertiesNotification";
NSString *const AMMapGridLayerChangedMajorGridLineSpacingNotification = @"AMMapGridLayerChangedMajorGridLineSpacingNotification";
NSString *const AMMapGridLayerChangedMinorGridLineSpacingNotification = @"AMMapGridLayerChangedMinorGridLineSpacingNotification";
NSString *const AMMapGridVisibilityChangedNotification = @"AMMapGridVisibilityChangedNotification";

@interface AMMapGridLayer (private)
- (AMSphericalCoordinates*) coordinatesForLongitude:(double)lon latitude:(double)lat inCoordinateSystems:(AMCoordinateSystem*)cs;
- (void) drawGridInRect:(NSRect)rect onPlot:(AMAstrometricMap*)map inView:(AMPlotView*)view  withMinimumLongitude:(double)minlon maximumLongitude:(double)maxlon  minimumLatitude:(double)minlat maximumLatitude:(double)maxlat inCoordinateSystem:(AMCoordinateSystem*)eqcs;
- (void) drawAxesInRect:(NSRect)rect onPlot:(AMAstrometricMap*)map inView:(AMPlotView*)view  withMinimumLongitude:(double)minlon maximumLongitude:(double)maxlon  minimumLatitude:(double)minlat maximumLatitude:(double)maxlat inCoordinateSystem:(AMCoordinateSystem*)eqcs;
- (BOOL) hasConvergentPoleWithMinimumLatitude:(double)minlat maximumLatitude:(double)maxlat inMap:(AMAstrometricMap*)map;
- (BOOL) hasConvergentNorthPoleWithMinimumLatitude:(double)minlat maximumLatitude:(double)maxlat inMap:(AMAstrometricMap*)map;
- (BOOL) hasConvergentSouthPoleWithMinimumLatitude:(double)minlat maximumLatitude:(double)maxlat inMap:(AMAstrometricMap*)map;
- (BOOL) needsLatitudeAxesInMap:(AMAstrometricMap*)map;
- (void) drawLabelsInSphericalViewWithRect:(NSRect)rect onPlot:(AMPlot*)plot inView:(AMPlotView*)view;
- (void) drawLabelsInRectangularViewWithRect:(NSRect)rect onPlot:(AMPlot*)plot inView:(AMPlotView*)view;
- (void) drawLatitudeLabelsOnVerticalAxisAtX:(CGFloat)x betweenY:(CGFloat)ymin andY:(CGFloat)ymax inMap:(AMAstrometricMap*)map leftSide:(BOOL)left;
- (void) drawLongitudeLabelsOnVerticalAxisAtX:(CGFloat)x betweenY:(CGFloat)ymin andY:(CGFloat)ymax inMap:(AMAstrometricMap*)map leftSide:(BOOL)left;
- (void) drawLongitudeLabelsOnHorizontalAxisAtY:(CGFloat)y betweenX:(CGFloat)xmin andX:(CGFloat)xmax inMap:(AMAstrometricMap*)map bottomSide:(BOOL)bottom;
- (void) drawLatitudeLabelsOnHorizontalAxisAtY:(CGFloat)y betweenX:(CGFloat)xmin andX:(CGFloat)xmax inMap:(AMAstrometricMap*)map bottomSide:(BOOL)bottom;
@end

@implementation AMMapGridLayer

- (id) init {
    self = [self initWithCoordinateSystem:[AMCoordinateSystem equatorialCoordinateSystemJ2000]];
    if(self){
    }
    return self;
}

- (id) initWithCoordinateSystem:(AMCoordinateSystem*)cs {
    self = [super init];
    if(self){
        _axisLineColor = [NSColor blackColor];
        _majorGridLineColor =[NSColor grayColor];
        _minorGridLineColor = [NSColor lightGrayColor];
        _axisLineWidth = 1.0;
        _majorGridLineWidth = 0.5;
        _minorGridLineWidth = 0.3;
        _drawGrid = YES;
        _minorLongitudeGridLineSpacing = 0.25;//15./360.;
        _minorLatitudeGridLineSpacing = 0.25;
        _majorLongitudeGridLineSpacing = 1.25;//0.25;
        _majorLatitudeGridLineSpacing = 1;
        _coordinateSystem = cs;
        _coordinateFont = [NSFont systemFontOfSize:11];
        _coordinateColor = [NSColor blackColor];
        _alwaysDrawFullCoordinateString = NO;
    }
    return self;
}

- (BOOL) allowAdditionOfLayerToPlot:(AMPlot*)plot {
    if([plot isKindOfClass:[AMAstrometricMap class]]) return YES; // for maps
    return NO;
}

#pragma mark Setters for properties

- (void) setDrawGrid:(BOOL)drawGrid {
    if([self drawGrid] != drawGrid){
        _drawGrid = drawGrid;
        [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridVisibilityChangedNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
    }
}

- (void) setRelativeMajorLongitudeGridLineSpacing:(double)relSpacing {
    _relativeMajorLongitudeGridLineSpacing = relSpacing;
    double scale = 1;
    if([[self plot] isKindOfClass:[AMAstrometricMap class]]){
        scale = [(AMAstrometricMap*)[self plot] scale];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setRelativeMinorLongitudeGridLineSpacing:(double)relSpacing {
    _relativeMinorLongitudeGridLineSpacing = relSpacing;
    double scale = 1;
    if([[self plot] isKindOfClass:[AMAstrometricMap class]]){
        scale = [(AMAstrometricMap*)[self plot] scale];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMajorLongitudeGridLineSpacing:(double) spacing {
    _majorLongitudeGridLineSpacing = spacing;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMinorLongitudeGridLineSpacing:(double) spacing {
    _minorLongitudeGridLineSpacing = spacing;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setRelativeMajorLatitudeGridLineSpacing:(double)relSpacing {
    _relativeMajorLatitudeGridLineSpacing = relSpacing;
    double scale = 1;
    if([[self plot] isKindOfClass:[AMAstrometricMap class]]){
        scale = [(AMAstrometricMap*)[self plot] scale];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setRelativeMinorLatitudeGridLineSpacing:(double)relSpacing {
    _relativeMinorLatitudeGridLineSpacing = relSpacing;
    double scale = 1;
    if([[self plot] isKindOfClass:[AMAstrometricMap class]]){
        scale = [(AMAstrometricMap*)[self plot] scale];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMajorLatitudeGridLineSpacing:(double) spacing {
    _majorLatitudeGridLineSpacing = spacing;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMinorLatitudeGridLineSpacing:(double) spacing {
    _minorLatitudeGridLineSpacing = spacing;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLineSpacingNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setAxisLineColor:(NSColor*) color {
    _axisLineColor = color;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLinePropertiesNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMajorGridLineColor:(NSColor*) color {
    _majorGridLineColor = color;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLinePropertiesNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMinorGridLineColor:(NSColor*) color {
    _minorGridLineColor = color;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLinePropertiesNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setAxisLineWidth:(CGFloat) width {
    _axisLineWidth = width;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLinePropertiesNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMajorGridLineWidth:(CGFloat) width {
    _majorGridLineWidth = width;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMajorGridLinePropertiesNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setMinorGridLineWidth:(CGFloat) width {
    _minorGridLineWidth = width;
    [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLinePropertiesNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
}

- (void) setCoordinateFont:(NSFont *)coordinateFont {
    if(![[self coordinateFont] isEqualTo:coordinateFont]){
        _coordinateFont = coordinateFont;
        [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLinePropertiesNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
    }
}

- (void) setCoordinateColor:(NSColor *)coordinateColor {
    if(![[self coordinateColor] isEqualTo:coordinateColor]){
        _coordinateColor = coordinateColor;
        [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLinePropertiesNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
    }
}
- (void) setAlwaysDrawFullCoordinateString:(BOOL)alwaysDrawFullCoordinateString {
    if([self alwaysDrawFullCoordinateString]!=alwaysDrawFullCoordinateString){
        _alwaysDrawFullCoordinateString = alwaysDrawFullCoordinateString;
        [[NSNotificationCenter defaultCenter] postNotificationName:AMMapGridLayerChangedMinorGridLinePropertiesNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:AMLayerChangedNotification object:self];
    }
}

#pragma mark Action

- (IBAction) changeMajorGridLineColor:(id)sender {
    
}

- (IBAction) changeMinorGridLineColor:(id)sender {
    
}

#pragma mark Nib loading

- (NSString*) listItemInfoPanelNibName {
    return nil;
}

- (NSString*) listItemTableCellViewNibName {
    return @"AMMapGridLayerTableCell";
}

- (void) didLoadTableCellViewNib{
    NSLog(@"Table cell view loaded nib");
    NSLog(@"Checkbox: %@",visibilityCB);
}

- (void) didLoadInfoPanelNib{
    
}

#pragma mark Layer drawing

- (void) drawRect:(NSRect)rect
           onPlot:(AMPlot*)plot
           inView:(AMPlotView*)view {
    AMCoordinateSystem *eqcs = [AMCoordinateSystem equatorialCoordinateSystemJ2000];
    AMAstrometricMap *map = (AMAstrometricMap*)plot;
    double maxlon = [[map maximumLongitude] value];
    double minlon = [[map minimumLongitude] value];
    double maxlat = [[map maximumLatitude] value];
    double minlat = [[map minimumLatitude] value];
    if(minlon>maxlon){
        maxlon+=360;
    }
    if([self drawGrid]){
        [self drawGridInRect:rect onPlot:map inView:view withMinimumLongitude:minlon maximumLongitude:maxlon minimumLatitude:minlat maximumLatitude:maxlat inCoordinateSystem:eqcs];
    }
    [self drawAxesInRect:rect onPlot:map inView:view withMinimumLongitude:minlon maximumLongitude:maxlon minimumLatitude:minlat maximumLatitude:maxlat inCoordinateSystem:eqcs];
}

- (void) drawGridInRect:(NSRect)rect onPlot:(AMAstrometricMap*)map inView:(AMPlotView*)view  withMinimumLongitude:(double)minlon maximumLongitude:(double)maxlon  minimumLatitude:(double)minlat maximumLatitude:(double)maxlat inCoordinateSystem:(AMCoordinateSystem*)eqcs{
    double scale = [map scale];
    if(scale<=0) return;
    double lon,lat;
    [[NSColor blackColor] set];
   // NSBezierPath *rbp = [NSBezierPath bezierPathWithRect:[map viewRect]];
   // [rbp stroke];
    
    [[self minorGridLineColor] set];
    double startlon = (double)((NSInteger) (minlon/[self minorLongitudeGridLineSpacing])+1)*[self minorLongitudeGridLineSpacing];
    double endlon = (double)((NSInteger) (maxlon/[self minorLongitudeGridLineSpacing]))*[self minorLongitudeGridLineSpacing];
    if(endlon<=startlon) endlon+=360;
    for(lon=startlon;lon<=endlon;lon+=[self minorLongitudeGridLineSpacing]){
        NSBezierPath *gridline = [NSBezierPath bezierPath];
        for(lat=minlat;lat<=maxlat;lat+=[self minorLatitudeGridLineSpacing]/50){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            if(NSPointInRect(point,[map viewRect])){
                if([gridline elementCount] <=0){
                    [gridline moveToPoint:point];
                }else {
                    [gridline lineToPoint:point];
                }
            }else{
                if([gridline elementCount] >0){
                    [gridline setLineWidth:[self minorGridLineWidth]];
                    [gridline stroke];
                    gridline = [NSBezierPath bezierPath];
                }
            }
        }
        if([gridline elementCount] >0){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:maxlat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            [gridline lineToPoint:point];
            [gridline setLineWidth:[self minorGridLineWidth]];
            [gridline stroke];
        }
    }
    double startlat = (double)((NSInteger) (minlat/[self minorLatitudeGridLineSpacing])+1)*[self minorLatitudeGridLineSpacing];
    double endlat = (double)((NSInteger) (maxlat/[self minorLatitudeGridLineSpacing]))*[self minorLatitudeGridLineSpacing];
    if(minlat<0){
        startlat = (double)((NSInteger) (minlat/[self minorLatitudeGridLineSpacing]))*[self minorLatitudeGridLineSpacing];
    }
    if(maxlat<0){
        endlat = (double)((NSInteger) (maxlat/[self minorLatitudeGridLineSpacing])-1)*[self minorLatitudeGridLineSpacing];
    }
    for(lat=startlat;lat<=endlat;lat+=[self minorLatitudeGridLineSpacing]){
        NSBezierPath *gridline = [NSBezierPath bezierPath];
        for(lon=minlon;lon<=maxlon;lon+=[self minorLongitudeGridLineSpacing]/50){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            if(NSPointInRect(point,[map viewRect])){
                if([gridline elementCount] <=0){
                    [gridline moveToPoint:point];
                }else {
                    [gridline lineToPoint:point];
                }
            }else{
                if([gridline elementCount] >0){
                    [gridline setLineWidth:[self minorGridLineWidth]];
                    [gridline stroke];
                    gridline = [NSBezierPath bezierPath];
                }
            }
        }
        if([gridline elementCount] >0){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:maxlon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            [gridline lineToPoint:point];
            [gridline setLineWidth:[self minorGridLineWidth]];
            [gridline stroke];
        }
    }
    [[self majorGridLineColor] set];
    startlon = (double)((NSInteger) (minlon/[self majorLongitudeGridLineSpacing])+1)*[self majorLongitudeGridLineSpacing];
    endlon = (double)((NSInteger) (maxlon/[self majorLongitudeGridLineSpacing]))*[self majorLongitudeGridLineSpacing];
    if(endlon<=startlon) endlon+=360;
    for(lon=startlon;lon<=endlon;lon+=[self majorLongitudeGridLineSpacing]){
        NSBezierPath *gridline = [NSBezierPath bezierPath];
        for(lat=minlat;lat<=maxlat;lat+=[self minorLatitudeGridLineSpacing]/50){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            if(NSPointInRect(point,[map viewRect])){
                if([gridline elementCount] <=0){
                    [gridline moveToPoint:point];
                }else {
                    [gridline lineToPoint:point];
                }
            }else{
                if([gridline elementCount] >0){
                    [gridline setLineWidth:[self majorGridLineWidth]];
                    [gridline stroke];
                    gridline = [NSBezierPath bezierPath];
                }
            }
        }
        if([gridline elementCount] >0){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:maxlat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            [gridline lineToPoint:point];
            [gridline setLineWidth:[self majorGridLineWidth]];
            [gridline stroke];
        }
    }
    startlat = (double)((NSInteger) (minlat/[self majorLatitudeGridLineSpacing])+1)*[self majorLatitudeGridLineSpacing];
    endlat = (double)((NSInteger) (maxlat/[self majorLatitudeGridLineSpacing]))*[self majorLatitudeGridLineSpacing];
    if(minlat<0){
        startlat = (double)((NSInteger) (minlat/[self majorLatitudeGridLineSpacing]))*[self majorLatitudeGridLineSpacing];
    }
    if(maxlat<0){
        endlat = (double)((NSInteger) (maxlat/[self majorLatitudeGridLineSpacing])-1)*[self majorLatitudeGridLineSpacing];
    }
    for(lat=startlat;lat<=endlat;lat+=[self majorLatitudeGridLineSpacing]){
        NSBezierPath *gridline = [NSBezierPath bezierPath];
        for(lon=minlon;lon<=maxlon;lon+=[self minorLongitudeGridLineSpacing]/50){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            if(NSPointInRect(point,[map viewRect])){
                if([gridline elementCount] <=0){
                    [gridline moveToPoint:point];
                }else {
                    [gridline lineToPoint:point];
                }
            }else{
                if([gridline elementCount] >0){
                    [gridline setLineWidth:[self majorGridLineWidth]];
                    [gridline stroke];
                    gridline = [NSBezierPath bezierPath];
                }
            }
        }
        if([gridline elementCount] >0){
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:maxlon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            [gridline lineToPoint:point];
            [gridline setLineWidth:[self majorGridLineWidth]];
            [gridline stroke];
        }
    }
}

- (void) drawAxesInRect:(NSRect)rect onPlot:(AMAstrometricMap*)map inView:(AMPlotView*)view  withMinimumLongitude:(double)minlon maximumLongitude:(double)maxlon  minimumLatitude:(double)minlat maximumLatitude:(double)maxlat inCoordinateSystem:(AMCoordinateSystem*)eqcs {
    [[self axisLineColor] set];
    if([map useRectangularViewPort]){
        NSBezierPath *bp = [NSBezierPath bezierPathWithRect:[map viewRect]];
        [bp setLineWidth:[self axisLineWidth]];
        [bp stroke];
    }else {
        NSBezierPath *bp = [NSBezierPath bezierPath];
        double lon,lat;
        BOOL convNP = [self hasConvergentNorthPoleWithMinimumLatitude:minlat maximumLatitude:maxlat inMap:map];
        BOOL convSP = [self hasConvergentSouthPoleWithMinimumLatitude:minlat maximumLatitude:maxlat inMap:map];
        BOOL latAxes = [self needsLatitudeAxesInMap:map];
        if(!convSP){
            double dlon = (maxlon-minlon)/100;
            if(dlon<=0) dlon = 0.1;
            for(lon = minlon;lon<=maxlon;lon+=dlon){
                AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:minlat inCoordinateSystems:eqcs];
                NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
                if([bp elementCount] <=0){
                    [bp moveToPoint:point];
                }else {
                    [bp lineToPoint:point];
                }
            }
        }
        if(latAxes){
            double dlat = (maxlat-minlat)/100;
            if(dlat<=0) dlat = 0.1;
            for(lat = minlat;lat<=maxlat;lat+=dlat){
                AMSphericalCoordinates *coord = [self coordinatesForLongitude:maxlon latitude:lat inCoordinateSystems:eqcs];
                NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
                if([bp elementCount] <=0){
                    [bp moveToPoint:point];
                }else {
                    [bp lineToPoint:point];
                }
            }
        }else{
            AMSphericalCoordinates *coord1 = [self coordinatesForLongitude:maxlon latitude:minlat inCoordinateSystems:eqcs];
            NSPoint point1 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord1]];
            AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:maxlon latitude:maxlat inCoordinateSystems:eqcs];
            NSPoint point2 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord2]];
            if([bp elementCount] <=0){
                [bp moveToPoint:point1];
                [bp moveToPoint:point2];
            }else {
                [bp lineToPoint:point1];
                [bp moveToPoint:point2];
            }
        }
        if(!convNP){
            double dlon = (maxlon-minlon)/100;
            if(dlon<=0) dlon = 0.1;
            for(lon = maxlon;lon>=minlon;lon-=dlon){
                AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:maxlat inCoordinateSystems:eqcs];
                NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
                if([bp elementCount] <=0){
                    [bp moveToPoint:point];
                }else {
                    [bp lineToPoint:point];
                }
            }
        }
        if(latAxes){
            double dlat = (maxlat-minlat)/100;
            if(dlat<=0) dlat = 0.1;
            for(lat = maxlat;lat>=minlat;lat-=dlat){
                AMSphericalCoordinates *coord = [self coordinatesForLongitude:minlon latitude:lat inCoordinateSystems:eqcs];
                NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
                if([bp elementCount] <=0){
                    [bp moveToPoint:point];
                }else {
                    [bp lineToPoint:point];
                }
            }
        }else{
            AMSphericalCoordinates *coord1 = [self coordinatesForLongitude:minlon latitude:maxlat inCoordinateSystems:eqcs];
            NSPoint point1 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord1]];
            AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:minlon latitude:minlat inCoordinateSystems:eqcs];
            NSPoint point2 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord2]];
            if([bp elementCount] <=0){
                [bp moveToPoint:point1];
                [bp moveToPoint:point2];
            }else {
                [bp lineToPoint:point1];
                [bp moveToPoint:point2];
            }
        }
        [bp closePath];
        [bp setLineWidth:[self axisLineWidth]];
        [bp stroke];
    }
}


#pragma mark Label drawing

- (void) drawLabelsInRect:(NSRect)rect
                   onPlot:(AMPlot*)plot
                   inView:(AMPlotView*)view {
    AMAstrometricMap *map = (AMAstrometricMap*)plot;
    if([map useRectangularViewPort]){
        [self drawLabelsInRectangularViewWithRect:rect onPlot:plot inView:view];
    }else {
        [self drawLabelsInSphericalViewWithRect:rect onPlot:plot inView:view];
    }
}


#pragma mark Drawing labels in a spherical view port

- (void) drawLabelsInSphericalViewWithRect:(NSRect)rect onPlot:(AMPlot*)plot inView:(AMPlotView*)view {
    [[self majorGridLineColor] set];
    AMCoordinateSystem *eqcs = [AMCoordinateSystem equatorialCoordinateSystemJ2000];
    AMAstrometricMap *map = (AMAstrometricMap*)[self plot];
    double maxlon = [[map maximumLongitude] value];
    double minlon = [[map minimumLongitude] value];
    double maxlat = [[map maximumLatitude] value];
    double minlat = [[map minimumLatitude] value];
    double startlon = (double)((NSInteger) (minlon/[self majorLongitudeGridLineSpacing])+1)*[self majorLongitudeGridLineSpacing];
    double endlon = (double)((NSInteger) (maxlon/[self majorLongitudeGridLineSpacing]))*[self majorLongitudeGridLineSpacing];
    if(endlon<=startlon) endlon+=360;
    double lon,lat;
    if(minlat>-90){
        for(lon=startlon;lon<=endlon;lon+=[self majorLongitudeGridLineSpacing]){
            lat = minlat;
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            if(NSPointInRect(point,rect)){
                NSAttributedString *string = [self attributedStringForLongitude:lon forCoordinateSystemType:[eqcs type] forceShowCompleteString:(lon==startlon || lon==endlon)];
                NSSize size = [string size];
                AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:lon latitude:minlat-[self minorLatitudeGridLineSpacing]/10. inCoordinateSystems:eqcs];
                NSPoint point2 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord2]];
                double angle = 180./M_PI*atan2((point2.y-point.y),(point2.x-point.x));
                NSPoint p = NSZeroPoint;
                if(angle>135){
                    angle-=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle<-135){
                    angle+=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle>45){
                    angle-=90;
                    p.x = -size.width/2;
                    p.y = +size.height*0.1;
                }else if(angle<-45){
                    angle+=90;
                    p.x = -size.width/2;
                    p.y = -size.height*1.1;
                }else {
                    p.x = +size.height*0.3;
                    p.y = -size.height/2;
                }
                [self drawAttributedString:string atPoint:p relativeToPivot:point withAngle:angle];
            }
        }
    }
    if(maxlat<90){
        for(lon=startlon;lon<=endlon;lon+=[self majorLongitudeGridLineSpacing]){
            lat = maxlat;
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            if(NSPointInRect(point,rect)){
                NSAttributedString *string = [self attributedStringForLongitude:lon forCoordinateSystemType:[eqcs type] forceShowCompleteString:(lon==startlon || lon==endlon)];
                NSSize size = [string size];
                AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:lon latitude:maxlat+[self minorLatitudeGridLineSpacing]/10. inCoordinateSystems:eqcs];
                NSPoint point2 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord2]];
                double angle = 180./M_PI*atan2((point2.y-point.y),(point2.x-point.x));
                NSPoint p = NSZeroPoint;
                if(angle>135){
                    angle-=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle<-135){
                    angle+=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle>45){
                    angle-=90;
                    p.x = -size.width/2;
                    p.y = +size.height*0.1;
                }else if(angle<-45){
                    angle+=90;
                    p.x = -size.width/2;
                    p.y = -size.height*1.1;
                }else {
                    p.x = +size.height*0.3;
                    p.y = -size.height/2;
                }
                [self drawAttributedString:string atPoint:p relativeToPivot:point withAngle:angle];
            }
        }
    }
    double startlat = (double)((NSInteger) (minlat/[self majorLatitudeGridLineSpacing])+1)*[self majorLatitudeGridLineSpacing];
    double endlat = (double)((NSInteger) (maxlat/[self majorLatitudeGridLineSpacing]))*[self majorLatitudeGridLineSpacing];
    if(minlat<0){
        startlat = (double)((NSInteger) (minlat/[self majorLatitudeGridLineSpacing]))*[self majorLatitudeGridLineSpacing];
    }
    if(maxlat<0){
        endlat = (double)((NSInteger) (maxlat/[self majorLatitudeGridLineSpacing])-1)*[self majorLatitudeGridLineSpacing];
    }
    
    // Prevent double latitude axes when one of the poles is included.
    BOOL singleLatAxes = ![self needsLatitudeAxesInMap:map];
    if(!singleLatAxes){
        for(lat=startlat;lat<=endlat;lat+=[self majorLatitudeGridLineSpacing]){
            lon = minlon;
            AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
            NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
            if(NSPointInRect(point,rect)){
                NSAttributedString *string = [self attributedStringForLatitude:lat forCoordinateSystemType:[eqcs type] forceShowCompleteString:(lat==startlat || lat==endlat)];
                NSSize size = [string size];
                AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:minlon-[self minorLongitudeGridLineSpacing]/10. latitude:lat inCoordinateSystems:eqcs];
                NSPoint point2 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord2]];
                double angle = 180./M_PI*atan2((point2.y-point.y),(point2.x-point.x));
                NSPoint p = NSZeroPoint;
                if(angle>135){
                    angle-=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle<-135){
                    angle+=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle>45){
                    angle-=90;
                    p.x = -size.width/2;
                    p.y = +size.height*0.1;
                }else if(angle<-45){
                    angle+=90;
                    p.x = -size.width/2;
                    p.y = -size.height*1.1;
                }else {
                    p.x = +size.height*0.3;
                    p.y = -size.height/2;
                }
                [self drawAttributedString:string atPoint:p relativeToPivot:point withAngle:angle];
            }
        }
    }
    for(lat=startlat;lat<=endlat;lat+=[self majorLatitudeGridLineSpacing]){
        lon = maxlon;
        AMSphericalCoordinates *coord = [self coordinatesForLongitude:lon latitude:lat inCoordinateSystems:eqcs];
        NSPoint point = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord]];
        if(NSPointInRect(point,rect)){
            NSAttributedString *string = [self attributedStringForLatitude:lat forCoordinateSystemType:[eqcs type] forceShowCompleteString:(lat==startlat || lat==endlat)];
            NSSize size = [string size];
            AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:maxlon+[self minorLongitudeGridLineSpacing]/10. latitude:lat inCoordinateSystems:eqcs];
            NSPoint point2 = [map locationInView:view forMeasures:[NSArray arrayWithObject:coord2]];
            double angle = 180./M_PI*atan2((point2.y-point.y),(point2.x-point.x));
            NSPoint p = NSZeroPoint;
            if(!singleLatAxes){
                if(angle>135){
                    angle-=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle<-135){
                    angle+=180;
                    p.x = -size.width-0.3*size.height;
                    p.y = -size.height/2;
                }else if(angle>45){
                    angle-=90;
                    p.x = -size.width/2;
                    p.y = +size.height*0.1;
                }else if(angle<-45){
                    angle+=90;
                    p.x = -size.width/2;
                    p.y = -size.height*1.1;
                }else {
                    p.x = +size.height*0.3;
                    p.y = -size.height/2;
                }
            }else{
                p.x = -size.width/2;
                p.y = -size.height/2;
                if(angle>135){
                    angle-=180;
                }else if(angle<-135){
                    angle+=180;
                }else if(angle>45){
                    angle-=90;
                }else if(angle<-45){
                    angle+=90;
                }else {
                }
            }
            [self drawAttributedString:string atPoint:p relativeToPivot:point withAngle:angle];
        }
    }
}

#pragma Drawing labels in a rectangular view port

- (void) drawLabelsInRectangularViewWithRect:(NSRect)rect onPlot:(AMPlot*)plot inView:(AMPlotView*)view {
    AMAstrometricMap *map = (AMAstrometricMap*)plot;
    NSRect viewRect = [map viewRect];
    CGFloat i;
    CGFloat dw = viewRect.size.width/10.;
    CGFloat dh = viewRect.size.height/10.;
    AMSphericalCoordinates *northpole = [AMSphericalCoordinates northPoleInCoordinateSystemType:[[[map centre] coordinateSystem] type]];
    AMSphericalCoordinates *southpole = [AMSphericalCoordinates southPoleInCoordinateSystemType:[[[map centre] coordinateSystem] type]];
    NSPoint np = [map locationInView:view forSphericalCoordinates:northpole];
    NSPoint sp = [map locationInView:view forSphericalCoordinates:southpole];
    BOOL includePole = NO;
    // Poles are included - latitude is drawn within map
    if(NSPointInRect(np, viewRect) || NSPointInRect(sp, viewRect)){
        includePole = YES;
        double lat;
        double lon = [[[map centre] longitude] value];
        double minlat = [[map minimumLatitude] value];
        double maxlat = [[map maximumLatitude] value];
        minlat = (double)[self majorLatitudeGridLineSpacing]*((NSInteger)(minlat/[self majorLatitudeGridLineSpacing]));
        maxlat = (double)[self majorLatitudeGridLineSpacing]*((NSInteger)(maxlat/[self majorLatitudeGridLineSpacing]));
        for(lat=minlat ; lat<=maxlat;lat+=[self majorLatitudeGridLineSpacing]){
            AMSphericalCoordinates *sc1 = [[AMSphericalCoordinates alloc] initWithCoordinateLongitude:[[AMScalarMeasure alloc] initWithQuantity:[[[map centre] longitude] quantity] numericalValue:lon andUnit:[[[map centre] longitude] unit]]  latitude:[[AMScalarMeasure alloc] initWithQuantity:[[[map centre] latitude] quantity] numericalValue:lat andUnit:[[[map centre] latitude] unit]] inCoordinateSystem:[[map centre] coordinateSystem]];
            AMSphericalCoordinates *sc2 = [[AMSphericalCoordinates alloc] initWithCoordinateLongitude:[[AMScalarMeasure alloc] initWithQuantity:[[[map centre] longitude] quantity] numericalValue:lon+[self minorLongitudeGridLineSpacing]/100 andUnit:[[[map centre] longitude] unit]]  latitude:[[AMScalarMeasure alloc] initWithQuantity:[[[map centre] latitude] quantity] numericalValue:lat andUnit:[[[map centre] latitude] unit]] inCoordinateSystem:[[map centre] coordinateSystem]];
            NSPoint point = [map locationInView:view forSphericalCoordinates:sc1];
            NSPoint point2 = [map locationInView:view forSphericalCoordinates:sc2];
            NSPoint p = NSZeroPoint;
            NSAttributedString *string = [self attributedStringForLatitude:lat forCoordinateSystemType:[[[map centre] coordinateSystem] type] forceShowCompleteString:YES];
            NSSize size = [string size];
            p.x = -size.width/2;
            p.y = -size.height/2;
            double angle = 180./M_PI*atan2((point2.y-point.y),(point2.x-point.x));
            if(angle>135){
                angle-=180;
            }else if(angle<-135){
                angle+=180;
            }else if(angle>45){
                angle-=90;
            }else if(angle<-45){
                angle+=90;
            }
            [self drawAttributedString:string atPoint:p relativeToPivot:point withAngle:angle];
        }
    }
    for(i=0;i<10;i++){
        if(!includePole){
            [self drawLatitudeLabelsOnVerticalAxisAtX:viewRect.origin.x betweenY:viewRect.origin.y+i*dh andY:viewRect.origin.y+(i+1)*dh inMap:map leftSide:YES];
            [self drawLatitudeLabelsOnVerticalAxisAtX:viewRect.origin.x+viewRect.size.width betweenY:viewRect.origin.y+i*dh andY:viewRect.origin.y+(i+1)*dh inMap:map leftSide:NO];
        }
        [self drawLongitudeLabelsOnHorizontalAxisAtY:viewRect.origin.y betweenX:viewRect.origin.x+i*dw andX:viewRect.origin.x+(i+1)*dw inMap:map bottomSide:YES];
        [self drawLongitudeLabelsOnHorizontalAxisAtY:viewRect.origin.y+viewRect.size.height betweenX:viewRect.origin.x+i*dw andX:viewRect.origin.x+(i+1)*dw inMap:map bottomSide:NO];
    }
    for(i=0;i<10;i++){
        [self drawLongitudeLabelsOnVerticalAxisAtX:viewRect.origin.x betweenY:viewRect.origin.y+i*dh andY:viewRect.origin.y+(i+1)*dh inMap:map leftSide:YES];
        [self drawLongitudeLabelsOnVerticalAxisAtX:viewRect.origin.x+viewRect.size.width betweenY:viewRect.origin.y+i*dh andY:viewRect.origin.y+(i+1)*dh inMap:map leftSide:NO];
        if(!includePole){
            [self drawLatitudeLabelsOnHorizontalAxisAtY:viewRect.origin.y betweenX:viewRect.origin.x+i*dw andX:viewRect.origin.x+(i+1)*dw inMap:map bottomSide:YES];
            [self drawLatitudeLabelsOnHorizontalAxisAtY:viewRect.origin.y+viewRect.size.height betweenX:viewRect.origin.x+i*dw andX:viewRect.origin.x+(i+1)*dw inMap:map bottomSide:NO];
        }
    }
}

- (void) drawLatitudeLabelsOnVerticalAxisAtX:(CGFloat)x betweenY:(CGFloat)ymin andY:(CGFloat)ymax inMap:(AMAstrometricMap*)map leftSide:(BOOL)left {
    CGFloat labelx = x-5;
    if(!left) labelx = x+5;
    NSPoint p1 = NSMakePoint(labelx, ymin);
    NSPoint p2 = NSMakePoint(labelx, ymax);
    AMSphericalCoordinates *sc1 = [map sphericalCoordinatesForLocation:p1 inViewRect:[map viewRect]];
    AMSphericalCoordinates *sc2 = [map sphericalCoordinatesForLocation:p2 inViewRect:[map viewRect]];
    NSInteger i1 = (NSInteger)([[sc1 latitude] value]/[self majorLatitudeGridLineSpacing]);
    if([[sc1 latitude] value]<0) i1--;
    NSInteger i2 = (NSInteger)([[sc2 latitude] value]/[self majorLatitudeGridLineSpacing]);
    if([[sc2 latitude] value]<0) i2--;
    if(i1!=i2){
        if(fabs(ymax-ymin)<0.5){
            double lat = [self majorLatitudeGridLineSpacing]*(double)((NSInteger)([[sc1 latitude] value]/[self majorLatitudeGridLineSpacing]+0.5));
            if([[sc1 latitude] value]<-[self majorLatitudeGridLineSpacing]*.1) lat-=[self majorLatitudeGridLineSpacing];
            NSLog(@"found lat: %f",lat);
            NSAttributedString *string = [self attributedStringForLatitude:lat forCoordinateSystemType:[[[map centre] coordinateSystem] type] forceShowCompleteString:YES];
            NSSize size = [string size];
            NSPoint sp = NSZeroPoint;
            if(left) sp.x -= size.width;
            sp.y -= size.height/2.;
            [self drawAttributedString:string atPoint:sp relativeToPivot:p1 withAngle:0];
        }else{
            double ymiddle = (ymin+ymax)/2.;
            [self drawLatitudeLabelsOnVerticalAxisAtX:x betweenY:ymin andY:ymiddle inMap:map leftSide:left];
            [self drawLatitudeLabelsOnVerticalAxisAtX:x betweenY:ymiddle andY:ymax inMap:map leftSide:left];
        }
    }
}

- (void) drawLongitudeLabelsOnVerticalAxisAtX:(CGFloat)x betweenY:(CGFloat)ymin andY:(CGFloat)ymax inMap:(AMAstrometricMap*)map leftSide:(BOOL)left {
    CGFloat labelx = x-5;
    if(!left) labelx = x+5;
    NSPoint p1 = NSMakePoint(labelx, ymin);
    NSPoint p2 = NSMakePoint(labelx, ymax);
    AMSphericalCoordinates *sc1 = [map sphericalCoordinatesForLocation:p1 inViewRect:[map viewRect]];
    AMSphericalCoordinates *sc2 = [map sphericalCoordinatesForLocation:p2 inViewRect:[map viewRect]];
    NSInteger i1 = (NSInteger)([[sc1 longitude] value]/[self majorLongitudeGridLineSpacing]);
    NSInteger i2 = (NSInteger)([[sc2 longitude] value]/[self majorLongitudeGridLineSpacing]);
    if(i1!=i2){
        if(fabs(ymax-ymin)<0.5){
            double lon = [self majorLongitudeGridLineSpacing]*(double)((NSInteger)([[sc1 longitude] value]/[self majorLongitudeGridLineSpacing]+0.5));
            NSAttributedString *string = [self attributedStringForLongitude:lon forCoordinateSystemType:[[[map centre] coordinateSystem] type] forceShowCompleteString:YES];
            NSSize size = [string size];
            NSPoint sp = NSZeroPoint;
            if(left) sp.x -= size.width;
            sp.y -= size.height/2.;
            [self drawAttributedString:string atPoint:sp relativeToPivot:p1 withAngle:0];
        }else{
            double ymiddle = (ymin+ymax)/2.;
            [self drawLongitudeLabelsOnVerticalAxisAtX:x betweenY:ymin andY:ymiddle inMap:map leftSide:left];
            [self drawLongitudeLabelsOnVerticalAxisAtX:x betweenY:ymiddle andY:ymax inMap:map leftSide:left];
        }
    }
}

- (void) drawLongitudeLabelsOnHorizontalAxisAtY:(CGFloat)y betweenX:(CGFloat)xmin andX:(CGFloat)xmax inMap:(AMAstrometricMap*)map bottomSide:(BOOL)bottom {
    CGFloat labely = y-5;
    if(!bottom) labely = y+5;
    NSPoint p1 = NSMakePoint(xmin,labely);
    NSPoint p2 = NSMakePoint(xmax,labely);
    AMSphericalCoordinates *sc1 = [map sphericalCoordinatesForLocation:p1 inViewRect:[map viewRect]];
    AMSphericalCoordinates *sc2 = [map sphericalCoordinatesForLocation:p2 inViewRect:[map viewRect]];
    NSInteger i1 = (NSInteger)([[sc1 longitude] value]/[self majorLongitudeGridLineSpacing]);
    NSInteger i2 = (NSInteger)([[sc2 longitude] value]/[self majorLongitudeGridLineSpacing]);
    if(i1!=i2){
        if(fabs(xmax-xmin)<0.5){
            double lon = [self majorLongitudeGridLineSpacing]*(double)((NSInteger)([[sc1 longitude] value]/[self majorLongitudeGridLineSpacing]+0.5));
            NSAttributedString *string = [self attributedStringForLongitude:lon forCoordinateSystemType:[[[map centre] coordinateSystem] type] forceShowCompleteString:YES];
            NSSize size = [string size];
            NSPoint sp = NSZeroPoint;
            if(bottom) sp.y -= size.height;
            sp.x -= size.width/2.;
            [self drawAttributedString:string atPoint:sp relativeToPivot:p1 withAngle:0];
        }else{
            double xmiddle = (xmin+xmax)/2.;
            [self drawLongitudeLabelsOnHorizontalAxisAtY:y betweenX:xmin andX:xmiddle inMap:map bottomSide:bottom];
            [self drawLongitudeLabelsOnHorizontalAxisAtY:y betweenX:xmiddle andX:xmax inMap:map bottomSide:bottom];
        }
    }
}

- (void) drawLatitudeLabelsOnHorizontalAxisAtY:(CGFloat)y betweenX:(CGFloat)xmin andX:(CGFloat)xmax inMap:(AMAstrometricMap*)map bottomSide:(BOOL)bottom {
    CGFloat labely = y-5;
    if(!bottom) labely = y+5;
    NSPoint p1 = NSMakePoint(xmin,labely);
    NSPoint p2 = NSMakePoint(xmax,labely);
    AMSphericalCoordinates *sc1 = [map sphericalCoordinatesForLocation:p1 inViewRect:[map viewRect]];
    AMSphericalCoordinates *sc2 = [map sphericalCoordinatesForLocation:p2 inViewRect:[map viewRect]];
    NSInteger i1 = (NSInteger)([[sc1 latitude] value]/[self majorLatitudeGridLineSpacing]);
    if([[sc1 latitude] value]<0) i1--;
    NSInteger i2 = (NSInteger)([[sc2 latitude] value]/[self majorLatitudeGridLineSpacing]);
    if([[sc2 latitude] value]<0) i2--;
    if(i1!=i2){
        if(fabs(xmax-xmin)<0.5){
            double lat = [self majorLatitudeGridLineSpacing]*(double)((NSInteger)([[sc1 latitude] value]/[self majorLatitudeGridLineSpacing]+0.5));
            if([[sc1 latitude] value]<-[self majorLatitudeGridLineSpacing]*.1) lat-=[self majorLatitudeGridLineSpacing];
            if(lat>[[map minimumLatitude] value] && lat<[[map maximumLatitude] value]){
                NSLog(@"found lat: %f",lat);
                NSAttributedString *string = [self attributedStringForLatitude:lat forCoordinateSystemType:[[[map centre] coordinateSystem] type] forceShowCompleteString:YES];
                NSSize size = [string size];
                NSPoint sp = NSZeroPoint;
                if(bottom) sp.y -= size.height;
                sp.x -= size.width/2.;
                [self drawAttributedString:string atPoint:sp relativeToPivot:p1 withAngle:0];
            }
        }else{
            double xmiddle = (xmin+xmax)/2.;
            [self drawLatitudeLabelsOnHorizontalAxisAtY:y betweenX:xmin andX:xmiddle inMap:map bottomSide:bottom];
            [self drawLatitudeLabelsOnHorizontalAxisAtY:y betweenX:xmiddle andX:xmax inMap:map bottomSide:bottom];
        }
    }
}


#pragma mark Converging to Pole

- (BOOL) hasConvergentPoleWithMinimumLatitude:(double)minlat maximumLatitude:(double)maxlat inMap:(AMAstrometricMap*)map andBetweenX:(CGFloat)minx andX:(CGFloat)maxx {
    BOOL cnp = [self hasConvergentNorthPoleWithMinimumLatitude:minlat maximumLatitude:maxlat inMap:map];
    if(cnp) return false;
    BOOL csp = [self hasConvergentSouthPoleWithMinimumLatitude:minlat maximumLatitude:maxlat inMap:map];
    return csp;
}

- (BOOL) hasConvergentNorthPoleWithMinimumLatitude:(double)minlat maximumLatitude:(double)maxlat inMap:(AMAstrometricMap*)map {
    BOOL conv = NO;
    if(maxlat==90){
        AMSphericalCoordinates *coord1 = [self coordinatesForLongitude:0 latitude:maxlat inCoordinateSystems:[[map centre] coordinateSystem]];
        NSPoint point1 = [map locationInView:nil forMeasures:[NSArray arrayWithObject:coord1]];
        AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:12 latitude:maxlat inCoordinateSystems:[[map centre] coordinateSystem]];
        NSPoint point2 = [map locationInView:nil forMeasures:[NSArray arrayWithObject:coord2]];
        if(fabs(point1.x-point2.x)<1. && fabs(point1.y-point2.y)<1.) conv = YES;
    }
    return conv;
}

- (BOOL) hasConvergentSouthPoleWithMinimumLatitude:(double)minlat maximumLatitude:(double)maxlat inMap:(AMAstrometricMap*)map {
    BOOL conv = NO;
    if(minlat==-90){
        AMSphericalCoordinates *coord1 = [self coordinatesForLongitude:0 latitude:minlat inCoordinateSystems:[[map centre] coordinateSystem]];
        NSPoint point1 = [map locationInView:nil forMeasures:[NSArray arrayWithObject:coord1]];
        AMSphericalCoordinates *coord2 = [self coordinatesForLongitude:12 latitude:minlat inCoordinateSystems:[[map centre] coordinateSystem]];
        NSPoint point2 = [map locationInView:nil forMeasures:[NSArray arrayWithObject:coord2]];
        if(fabs(point1.x-point2.x)<1. && fabs(point1.y-point2.y)<1.) conv = YES;
    }
    return conv;
}

- (BOOL) needsLatitudeAxesInMap:(AMAstrometricMap*)map {
    double clat = [[[map centre] latitude] value];
    if(clat==90) return ![self hasConvergentNorthPoleWithMinimumLatitude:89 maximumLatitude:90 inMap:map];
    if(clat==-90) return ![self hasConvergentSouthPoleWithMinimumLatitude:-90 maximumLatitude:-89 inMap:map];
    return YES;
}

#pragma mark Creating Attributed strings for angles (latitude and longitude)

- (NSAttributedString*) attributedStringForLongitude:(double)lon forCoordinateSystemType:(AMCoordinateSystemType)type forceShowCompleteString:(BOOL)complete {
    while(lon>=360) lon-=360;
    while(lon<0) lon+=360;
    if(type==AMEquatortialCoordinateSystem){
        NSFont *superScriptFont = [[NSFontManager sharedFontManager] convertFont:[self coordinateFont] toSize:[[self coordinateFont] pointSize]-2];
        NSDictionary *coordAttr = [NSDictionary dictionaryWithObjectsAndKeys:[self coordinateFont],NSFontAttributeName, nil];
        NSDictionary *superscriptAttr = [NSDictionary dictionaryWithObjectsAndKeys:superScriptFont,NSFontAttributeName,[NSNumber numberWithInteger:1],NSSuperscriptAttributeName, nil];
        double dh = [self majorLongitudeGridLineSpacing]/15.;
        if(dh>=1){
            int h = (int)(lon/15.+0.5);
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",h] attributes:coordAttr]];
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"h" attributes:superscriptAttr]];
            return string;
        } else if(dh>=0.016){
            int h = (int)(lon/15.);
            int m = (int)(((lon/15.-(double)h)*60)+0.5);
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            if(m==0 || complete || [self alwaysDrawFullCoordinateString]){
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",h] attributes:coordAttr]];
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"h" attributes:superscriptAttr]];
            }
            NSString *mstr = nil;
            if(m<10){
                mstr = [NSString stringWithFormat:@"0%d",m];
            }else{
                mstr = [NSString stringWithFormat:@"%d",m];
            }
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:mstr attributes:coordAttr]];
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"m" attributes:superscriptAttr]];
            return string;
        } else if(dh>=0.00026){
            int h = (int)(lon/15.);
            int m = (int)((lon/15.-(double)h)*60);
            int s = (int)((lon/15.-(double)h-(double)m/60.)*3600+0.5);
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            if(s==0 || complete || [self alwaysDrawFullCoordinateString]){
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",h] attributes:coordAttr]];
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"h" attributes:superscriptAttr]];
                NSString *mstr = nil;
                if(m<10){
                    mstr = [NSString stringWithFormat:@"0%d",m];
                }else{
                    mstr = [NSString stringWithFormat:@"%d",m];
                }
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:mstr attributes:coordAttr]];
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"m" attributes:superscriptAttr]];
            }
            NSString *sstr = nil;
            if(s<10){
                sstr = [NSString stringWithFormat:@"0%d",s];
            }else{
                sstr = [NSString stringWithFormat:@"%d",s];
            }
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:sstr attributes:coordAttr]];
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:@"s" attributes:superscriptAttr]];
            return string;
        }
    }else{
        NSDictionary *coordAttr = [NSDictionary dictionaryWithObjectsAndKeys:[self coordinateFont],NSFontAttributeName, nil];
        double dg = [self majorLatitudeGridLineSpacing];
        if(dg>=1){
            int deg = (int)(lon+0.5);
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d°",deg] attributes:coordAttr]];
            return string;
        }else if(dg>=0.016){
            int deg = (int)(lon);
            int min = (int)((lon-(double)deg)*60+0.5);
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            NSString* mstr = nil;
            if(min<10){
                mstr = [NSString stringWithFormat:@"0%d",min];
            }else{
                mstr = [NSString stringWithFormat:@"%d",min];
            }
            if(min==0 || complete || [self alwaysDrawFullCoordinateString]){
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d°",deg] attributes:coordAttr]];
            }
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@'",mstr] attributes:coordAttr]];
            return string;
        }else if(dg>=0.00027){
            int deg = (int)(lon);
            int min = (int)((lon-(double)deg)*60);
            int sec = (int)((lon-(double)deg-(double)min/60.)*3600+0.5);
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
            NSString* mstr = nil;
            if(min<10){
                mstr = [NSString stringWithFormat:@"0%d",min];
            }else{
                mstr = [NSString stringWithFormat:@"%d",min];
            }
            NSString* sstr = nil;
            if(sec<10){
                sstr = [NSString stringWithFormat:@"0%d",sec];
            }else{
                sstr = [NSString stringWithFormat:@"%d",sec];
            }
            if(sec==0 || complete || [self alwaysDrawFullCoordinateString]){
                [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d°%@'",deg,mstr] attributes:coordAttr]];
            }
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\"",sstr] attributes:coordAttr]];
            return string;
        }
    }
    return nil;
}

- (NSAttributedString*) attributedStringForLatitude:(double)lat forCoordinateSystemType:(AMCoordinateSystemType)type forceShowCompleteString:(BOOL)complete {
    NSDictionary *coordAttr = [NSDictionary dictionaryWithObjectsAndKeys:[self coordinateFont],NSFontAttributeName, nil];
    double dg = [self majorLatitudeGridLineSpacing];
    NSString *sign = @"+";
    if(lat<0) sign = @"-";
    if(lat==0) sign = @"";
    lat = fabs(lat);
    if(dg>=1){
        int deg = (int)(lat+0.5);
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%d°",sign,deg] attributes:coordAttr]];
        return string;
    }else if(dg>=0.016){
        int deg = (int)(lat);
        int min = (int)((lat-(double)deg)*60+0.5);
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
        NSString* mstr = nil;
        if(min<10){
            mstr = [NSString stringWithFormat:@"0%d",min];
        }else{
            mstr = [NSString stringWithFormat:@"%d",min];
        }
        if(min==0 || complete || [self alwaysDrawFullCoordinateString]){
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%d°",sign,deg] attributes:coordAttr]];
        }
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@'",mstr] attributes:coordAttr]];
        return string;
    }else if(dg>=0.00027){
        int deg = (int)(lat);
        int min = (int)((lat-(double)deg)*60);
        int sec = (int)((lat-(double)deg-(double)min/60.)*3600+0.5);
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
        NSString* mstr = nil;
        if(min<10){
            mstr = [NSString stringWithFormat:@"0%d",min];
        }else{
            mstr = [NSString stringWithFormat:@"%d",min];
        }
        NSString* sstr = nil;
        if(sec<10){
            sstr = [NSString stringWithFormat:@"0%d",sec];
        }else{
            sstr = [NSString stringWithFormat:@"%d",sec];
        }
        if(sec==0 || complete || [self alwaysDrawFullCoordinateString]){
            [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%d°%@'",sign,deg,mstr] attributes:coordAttr]];
        }
        [string appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\"",sstr] attributes:coordAttr]];
        return string;
    }
    return nil;
}



- (AMSphericalCoordinates*) coordinatesForLongitude:(double)lon latitude:(double)lat inCoordinateSystems:(AMCoordinateSystem*)cs {
    AMSphericalCoordinates *coord = [[AMSphericalCoordinates alloc] initWithCoordinateLongitude:[[AMScalarMeasure alloc] initWithQuantity:[AMQuantity quantityWithName:@"Right ascension"] numericalValue:lon andUnit:[AMUnit unitWithName:@"degree"]] latitude:[[AMScalarMeasure alloc] initWithQuantity:[AMQuantity quantityWithName:@"Declination"] numericalValue:lat andUnit:[AMUnit unitWithName:@"degree"]] inCoordinateSystem:cs];
    return coord;
}

@end

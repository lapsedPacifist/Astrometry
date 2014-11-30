//
//  AMCoordinateSystem.m
//  Astrometry
//
//  Created by Don Willems on 23/11/14.
//  Copyright (c) 2014 lapsedpacifist. All rights reserved.
//

#import "AMCoordinateSystem.h"

@implementation AMCoordinateSystem

+ (AMCoordinateSystem*) equatorialCoordinateSystemJ2000 {
    AMCoordinateSystem *system = [[AMCoordinateSystem alloc] initWithType:AMEquatortialCoordinateSystem inEquinox:nil onEpoch:nil];
    return system;
}

+ (AMCoordinateSystem*) equatorialCoordinateSystemJ2000AtEpoch:(NSDate*)epoch {
    AMCoordinateSystem *system = [[AMCoordinateSystem alloc] initWithType:AMEquatortialCoordinateSystem inEquinox:nil onEpoch:epoch];
    return system;
}

+ (AMCoordinateSystem*) galacticCoordinateSystem {
    return nil;
}

- (id) initWithType:(AMCoordinateSystemType)type inEquinox:(NSDate*)equinox onEpoch:(NSDate*)epoch {
    self = [super init];
    if(self){
        _type = type;
        _equinox = equinox;
        _epoch = epoch;
    }
    return self;
}

- (BOOL) isEqual:(id)object {
    if([object isKindOfClass:[AMCoordinateSystem class]]){
        AMCoordinateSystem *cs = (AMCoordinateSystem*)object;
        if([cs type] != [self type]) return NO;
        if(![[self epoch] isEqualToDate:[cs epoch]]) return NO;
        if(![[self equinox] isEqualToDate:[cs equinox]]) return NO;
    }
    return NO;
}
@end

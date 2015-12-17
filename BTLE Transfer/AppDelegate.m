/*
 
 This code is a modified version of the BTLE Transfer iOS app available for
 download at:
 
    https://developer.apple.com/library/ios/samplecode/BTLE_Transfer/Introduction/Intro.html
 
 The modifications are:
 - removed Bluetooth Central Manager code
 - removed all UI code with exception of first screen
 - moved all CBPeripheral to AppDelegate class
 - reworked CBPeripheral code so that it can operate as a background task
 
 Bob Dugan December 2015
 
 ----------------------- Begin Apple Comments -------------------------
 
 File: AppDelegate.m
 
 Abstract: App Level Code
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "AppDelegate.h"

@interface AppDelegate () <CBPeripheralManagerDelegate>
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // If the launchOptions are NULL, then the app is started as a foreground task otherwise
    // the app is started as a background task.
    NSLog(@"%s: launchOptions:%@ %@",__PRETTY_FUNCTION__,launchOptions,(launchOptions==nil)?@"FOREGROUND TASK":@"BACKGROUND TASK");

    
    // Start up the CBPeripheralManager
    //
    // This version allows the SERVICE UUID for the BTLE service supported by CBPeripheralManager
    // to move to an overflow buffer on the iOS device... this overflow buffer can be queried
    // EVEN WHEN THE APP IS NOT RUNNING so that it can be started as a background task on the
    // iOS device.
    //
    // OLD VERSION:
    //   _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    //
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate: self queue:nil options:@{ CBCentralManagerOptionRestoreIdentifierKey:@"peripheralManagerIdentifier" }];
    
    [BackgroundTimeRemainingUtility NSLog];
   
    return YES;
}
							
//
// Delegate for UIApplicationDelegate
//
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)()) completionHandler
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

//
// Delegate for UIApplicationDelegate
//
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

//
// Delegate for UIApplicationDelegate
//
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

//
// Delegate for UIApplicationDelegate
//
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

//
// Delegate for UIApplicationDelegate
//
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

//
// Delegate for UIApplicationDelegate
//
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

//
// Delegate for UIApplicationDelegate
//
- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - Peripheral Methods

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // CBPeripheralManagerState... state other than CBPeripheralManagerStatePoweredOn
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"%s: peripheralManager state is now: %li",__PRETTY_FUNCTION__,(long)peripheral.state);
    }
    // CBPeripheralManagerStatePoweredOn state...
    else {
        
        NSLog(@"%s: peripheralManager powered on.",__PRETTY_FUNCTION__);
        [BackgroundTimeRemainingUtility NSLog];
        
        // Start with the CBMutableCharacteristic
        _transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
        
        // Then the service
        _transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID] primary:YES];
        
        // Add the characteristic to the service
        _transferService.characteristics = @[_transferCharacteristic];
        
        // And add it to the peripheral manager
        [_peripheralManager addService:_transferService];
        
        // Start advertising using a timed thread... this won't work without a timer because you must have time to for
        // the peripheral manager to add the service.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [_peripheralManager stopAdvertising];
            [_peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : @[_transferService.UUID] }];
            NSLog(@"%s: started advertising with ServiceUUID: %@ and CharacteristicUUID: %@",__PRETTY_FUNCTION__,_transferService.UUID,_transferCharacteristic.UUID);
        });
    }
}


//
// Delegate for CBPeripheralDelegate
//
// Start sending data once we've got a subscriber to the characteristic
//
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    
    NSLog(@"%s: central subscribed to characteristic: localkey: %@ dataserviceUUIDs: %@ datasolicitedserviceuuidskey: %@",__PRETTY_FUNCTION__,CBAdvertisementDataLocalNameKey,CBAdvertisementDataServiceUUIDsKey,CBAdvertisementDataSolicitedServiceUUIDsKey);
    [BackgroundTimeRemainingUtility NSLog];
    
    // Get the data
    self.dataToSend = [@"Hello from a bluetooth peripheral.  Hope you get this just fine!" dataUsingEncoding:NSUTF8StringEncoding];
    
    // Reset the index
    self.sendDataIndex = 0;
    
    // Start sending
    [self sendData];
}

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    NSLog(@"%s:",__PRETTY_FUNCTION__);
    [BackgroundTimeRemainingUtility NSLog];
    
    // Start sending again
    [self sendData];
}

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"%s: central unsubscribed from characteristic (s)",__PRETTY_FUNCTION__);
    [BackgroundTimeRemainingUtility NSLog];
}

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
{
    NSLog(@"%s: service:%@ error:%@ ",__PRETTY_FUNCTION__,service,error);
    [BackgroundTimeRemainingUtility NSLog];
}

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
{
    NSLog(@"%s: peripheral:%@ error:%@ ",__PRETTY_FUNCTION__,peripheral,error);
    [BackgroundTimeRemainingUtility NSLog];
}

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request
{
    NSLog(@"%s: peripheral:%@ request:%@ ",__PRETTY_FUNCTION__,peripheral,request);
    [BackgroundTimeRemainingUtility NSLog];
}

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests
{
    NSLog(@"%s: peripheral:%@ request:%@ ",__PRETTY_FUNCTION__,peripheral,requests);
    [BackgroundTimeRemainingUtility NSLog];
}

//
// Delegate for CBPeripheralDelegate
//
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict
{
    NSLog(@"%s: peripheral:%@ request:%@ ",__PRETTY_FUNCTION__,peripheral,dict);
    [BackgroundTimeRemainingUtility NSLog];
}

//
// Sends the next amount of data to the connected central
//
- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    NSLog(@"%s:",__PRETTY_FUNCTION__);
    [BackgroundTimeRemainingUtility NSLog];
    
    // Special case if we're done sending the message
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            // It did, so mark it as sent
            sendingEOM = NO;
            NSLog(@"%s: send EOM succeeded.",__PRETTY_FUNCTION__);
        }
        else {
            NSLog(@"%s: send EOM failed.. will try again.",__PRETTY_FUNCTION__);
        }
    }
    // We're not sending an EOM, so we're sending data
    else {
        
        // Is there any left to send?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // No data left.  Do nothing
            return;
        }
        
        // There's data left, so send until the callback fails, or we're done.
        BOOL didSend = YES;
        while (didSend) {
            
            // Make the next chunk
            
            // Work out how big it should be
            NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
            
            // Can't be longer than 20 bytes
            if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
            
            // Copy out the data we want
            NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
            
            // Send it
            didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            // If it didn't work, drop out and wait for the callback
            if (!didSend) {
                return;
            }
            
            NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
            NSLog(@"Sent: %@", stringFromData);
            
            // It did send, so update our index
            self.sendDataIndex += amountToSend;
            
            // Was it the last one?
            if (self.sendDataIndex >= self.dataToSend.length) {
                
                // It was - send an EOM
                
                // Set this so if the send fails, we'll send it next time
                sendingEOM = YES;
                
                // Send it
                BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
                
                if (eomSent) {
                    // It sent, we're all done
                    sendingEOM = NO;
                    
                    NSLog(@"Sent: EOM");
                }
                
                return;
            }
        }
    }
}
@end

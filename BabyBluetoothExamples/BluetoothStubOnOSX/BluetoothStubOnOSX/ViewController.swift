//
//  ViewController.swift
//  BluetoothStubOnOSX
//
//  Created by ZTELiuyw on 15/9/30.
//  Copyright © 2015年 liuyanwei. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController,CBPeripheralManagerDelegate{

//MARK:- static parameter

    let localNameKey =  "BabyBluetoothStubOnOSX";
    let ServiceUUID =  "6F26CE21-DA83-449D-B9A6-E3E43F5DC639";
    let notiyCharacteristicUUID =  "977F0ED0-E9F5-4249-B0DB-A02EA5BD0CC1";
    let readCharacteristicUUID =  "2055CFFC-6899-492D-B673-5B486B9E8786";
    let readwriteCharacteristicUUID =  "19651AB4-23B1-4215-B807-5B636D0F42FD";
    
    var peripheralManager:CBPeripheralManager!
	var timer:Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }
    
    //publish service and characteristic
    func publishService(){
        
		let notiyCharacteristic = CBMutableCharacteristic(type: CBUUID(string: notiyCharacteristicUUID), properties:  [CBCharacteristicProperties.notify], value: nil, permissions: CBAttributePermissions.readable)
		let readCharacteristic = CBMutableCharacteristic(type: CBUUID(string: readCharacteristicUUID), properties:  [CBCharacteristicProperties.read], value: nil, permissions: CBAttributePermissions.readable)
		let writeCharacteristic = CBMutableCharacteristic(type: CBUUID(string: readwriteCharacteristicUUID), properties:  [CBCharacteristicProperties.write,CBCharacteristicProperties.read], value: nil, permissions: [CBAttributePermissions.readable,CBAttributePermissions.writeable])
        
        //设置description
        let descriptionStringType = CBUUID(string: CBUUIDCharacteristicUserDescriptionString)
        let description1 = CBMutableDescriptor(type: descriptionStringType, value: "canNotifyCharacteristic")
        let description2 = CBMutableDescriptor(type: descriptionStringType, value: "canReadCharacteristic")
        let description3 = CBMutableDescriptor(type: descriptionStringType, value: "canWriteAndWirteCharacteristic")
        notiyCharacteristic.descriptors = [description1]
        readCharacteristic.descriptors = [description2]
        writeCharacteristic.descriptors = [description3]
        
        //设置service
        let service:CBMutableService =  CBMutableService(type: CBUUID(string: ServiceUUID), primary: true)
        service.characteristics = [notiyCharacteristic,readCharacteristic,writeCharacteristic]
		peripheralManager.add(service)
    }
    //发送数据，发送当前时间的秒数
	func sendData(t:Timer)->Bool{
        let characteristic = t.userInfo as!  CBMutableCharacteristic;
		let dft = DateFormatter();
        dft.dateFormat = "ss";
		NSLog("%@",dft.string(from: NSDate() as Date))
        
        //执行回应Central通知数据
		return peripheralManager.updateValue(dft.string(from: NSDate() as Date).data(using: String.Encoding.utf8)!, for: characteristic, onSubscribedCentrals: nil)
    }

    //MARK:- CBPeripheralManagerDelegate
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		switch peripheral.state{
		case .poweredOn:
			NSLog("power on")
			publishService();
		case .poweredOff:
			NSLog("power off")
		default:
			print(">>>设备不支持BLE或者是未打开蓝牙")
			break;
		}
	}
	
	func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
		peripheralManager.startAdvertising(
			[
				CBAdvertisementDataServiceUUIDsKey : [CBUUID(string: ServiceUUID)]
				,CBAdvertisementDataLocalNameKey : localNameKey
			]
		)
	}
	
	func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
		print("peripheralManagerIsReady")
	}
	
	func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("in peripheralManagerDidStartAdvertisiong");
    }
    
    //订阅characteristics
	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
		print("订阅了 \(characteristic.uuid)的数据")
		//每秒执行一次给主设备发送一个当前时间的秒数
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector:Selector(("sendData:")) , userInfo: characteristic, repeats: true)
	}
	
    //取消订阅characteristics
	
	func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
		NSLog("取消订阅 \(characteristic.uuid)的数据")
        //取消回应
        timer.invalidate()
    }
   
    
    //读characteristics请求
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
		print("didReceiveReadRequest")
		//判断是否有读数据的权限
		if(request.characteristic.properties.contains(CBCharacteristicProperties.read))
		{
			request.value = request.characteristic.value;
			peripheral .respond(to: request, withResult: .success);
		}
		else{
			peripheral .respond(to: request, withResult: .readNotPermitted);
		}
	}
	
	func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
		print("didReceiveWriteRequests")
		let request:CBATTRequest = requests[0];
		
		//判断是否有写数据的权限
		if (request.characteristic.properties.contains(CBCharacteristicProperties.write)) {
			//需要转换成CBMutableCharacteristic对象才能进行写值
			let c:CBMutableCharacteristic = request.characteristic as! CBMutableCharacteristic
			c.value = request.value;
			let tempValue:NSString = NSString.init(data: request.value!, encoding: String.Encoding.utf8.rawValue)!
			print("tempValue:\(tempValue)")
			peripheral .respond(to: request, withResult: .success);
		}else{
			peripheral .respond(to: request, withResult: .readNotPermitted);
		}
	}

    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
            print("peripheralManagerIsReadyToUpdateSubscribers")
    }
}


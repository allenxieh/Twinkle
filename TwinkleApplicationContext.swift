//
//  TwinkleApplicationContext.swift
//  ProjectTemplete
//
//  Created by allen on 16/6/30.
//  Copyright © 2016年 com.allen. All rights reserved.
//

import Foundation

class TwinkleApplicationContext: NSObject {
    static let sharedInstance = TwinkleApplicationContext()
    private override init(){}
    
    private let XMLManager = TwinkleXMLManager.sharedInstance
    
}

extension TwinkleApplicationContext{
    func getBean(className className: String) -> AnyObject? {
        return XMLManager.getBean(className: className)
    }
    
    func getBean(protocolName protocolName:String) -> AnyObject? {
        return XMLManager.getBean(protocolName: protocolName)
    }
}
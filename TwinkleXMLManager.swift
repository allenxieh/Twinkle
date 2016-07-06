//
//  TwinkleXMLManager.swift
//  ProjectTemplete
//
//  Created by allen on 16/6/30.
//  Copyright © 2016年 com.allen. All rights reserved.
//

import Foundation
@objc
class TwinkleXMLManager: NSObject {
    
    enum GetBeanByType {
        case GetBeanByClass, GetBeanByProtocol
    }
    
    private let __kPropertyKey__        = "property"
    private let __kBeanKey__            = "bean"
    private let __kProtocolNameKey__    = "protocolName"
    private let __kClassNameKey__       = "className"
    private let __kIdKey__              = "id"
    private let __kRefKey__             = "ref"
    private let __kNameKey__            = "name"
    private let __kScopeKey__           = "scope"
    private let __kScopeTypeSingleton__ = "singleton"
    
    private var rootXmlDoc:GDataXMLDocument?
    private var rootElement:GDataXMLElement?
    private var beanElements:[GDataXMLElement] = Array()
    private var xmlDocArr:[GDataXMLDocument] = Array()
    private var singletons:[String:AnyObject] = Dictionary()
    private var classCache:[String:AnyClass] = Dictionary()
    private var initializingClassPool:[String:String] = Dictionary()
    
    static let sharedInstance = TwinkleXMLManager()
    private override init(){
        super.init()
        
        func readXML(path:String) -> GDataXMLDocument?{
            var gGataXMLDocument:GDataXMLDocument?
            if let path = NSBundle.mainBundle().pathForResource(path, ofType: nil){
                let xmlData = NSData(contentsOfFile: path)
                if let xmlData = xmlData {
                    if path.hasSuffix("xml") {
                        do {
                            try gGataXMLDocument = GDataXMLDocument(data: xmlData, options: 0)
                        } catch{
                            printLog("\(error)")
                        }
                        
                    }else{
                        // TODO:文件解密
                    }
                }
            }else{
                fatalError("读取文件<\(path)>错误")
            }
            return gGataXMLDocument
        }
        
        //将class缓存至内存
        func cacheClass(beans:[GDataXMLElement]){
            classCache = Dictionary()
            var tempClassCache:[String:String] = Dictionary()
            for element in beans {
                
                let idValue = element.attributeForName(__kIdKey__).stringValue()
                if idValue != nil {
                    if tempClassCache[idValue] == nil {
                        tempClassCache[idValue] = idValue
                    }else{
                        fatalError("id<\(idValue)>重复定义")
                    }
                }
                
                if element.attributeForName(__kClassNameKey__) != nil {
                    let classNameValue = element.attributeForName(__kClassNameKey__).stringValue()
                        guard let classType = swiftClassFromString(classNameValue) else{
                            fatalError("class<\(classNameValue)>加载失败")
                        }
                        classCache[classNameValue] = classType
                    }
            
                
                
                if element.children() != nil {
                    for childrenClassElement in element.children() as! [GDataXMLElement] {
                        if childrenClassElement.attributeForName(__kClassNameKey__) != nil {
                            let childrenClassNameValue = childrenClassElement.attributeForName(__kClassNameKey__).stringValue()
                            guard let classType = swiftClassFromString(childrenClassNameValue) else{
                                fatalError("class<\(childrenClassNameValue)>加载失败")
                            }
                            classCache[childrenClassNameValue] = classType
                        }
                    }
                }
            }
        }
        
        rootXmlDoc = readXML(__kXMLPath__)
        
        guard let rootXmlDoc = rootXmlDoc else {
            return
        }
        
        rootElement = rootXmlDoc.rootElement()
        
//        var mBeanArr:[GDataXMLElement] = Array()
        xmlDocArr = Array()
        
        guard let packageElement = try! rootElement?.nodesForXPath("package") else{
            return
        }
        
        for xmlElement in packageElement {
            let xmlPath = xmlElement.attributeForName("name").stringValue()
            if let XMLDocTemp = readXML(xmlPath){
                let rootElementTemp = XMLDocTemp.rootElement()
                xmlDocArr.append(XMLDocTemp)
                beanElements += try! rootElementTemp.nodesForXPath("beans/bean") as! [GDataXMLElement]
            }
        }
        
        //启动时检查id及class
        cacheClass(beanElements)
    }
}
extension TwinkleXMLManager{
    private func getBean(name:String, type:GetBeanByType) -> AnyObject?{
        
        var instance:AnyObject?
        
        for beanElement in beanElements {
            switch type {
            case .GetBeanByClass:
                if beanElement.attributeForName(__kClassNameKey__) != nil {
                    if beanElement.attributeForName(__kClassNameKey__).stringValue() == name {
                        if beanElement.children() == nil {//没有property子标签
                            instance = loadBean(className: name)
                        }
                        else{//获取bean实例
                            if initializingClassPool[name] != nil {
                                fatalError("<\(name)>循环依赖")
                            }
                            instance = loadBean(className: name)
                            initializingClassPool[name] = name
                            let properties = try! beanElement.nodesForXPath(__kPropertyKey__) as! [GDataXMLElement]
                            if properties.count > 0 {
                                for propertyElement in properties {
                                    var subInstance:AnyObject?
                                    if propertyElement.attributeForName(__kProtocolNameKey__) == nil {//没有protocolName属性
                                        if propertyElement.attributeForName(__kRefKey__) == nil {//没有ref属性
                                            subInstance = loadBean(className: propertyElement.attributeForName(__kClassNameKey__).stringValue())
                                        }else{
                                            subInstance = loadBean(id: propertyElement.attributeForName(__kRefKey__).stringValue())
                                        }
                                        if let subInstance = subInstance {
                                            if isSingleton(propertyElement) {
                                                singletons[String(subInstance)] = subInstance
                                            }
                                            guard propertyElement.attributeForName(__kNameKey__) != nil else {
                                                fatalError("<\(beanElement.attributeForName(__kClassNameKey__).stringValue())->\(propertyElement.attributeForName(__kClassNameKey__).stringValue())>找不到'name'属性")
                                            }
                                            instance?.setValue(subInstance, forKey: propertyElement.attributeForName(__kNameKey__).stringValue())
                                            
                                        }
                                    }
                                    else
                                    {
                                        let aProtocol = NSProtocolFromString(propertyElement.attributeForName(__kProtocolNameKey__).stringValue())
                                        subInstance = loadBean(id: propertyElement.attributeForName(__kRefKey__).stringValue())
                                        if let subInstance = subInstance {
                                            if isSingleton(propertyElement) {
                                                singletons[String(subInstance)] = subInstance
                                            }
                                            if let aProtocol = aProtocol{
                                                if subInstance.conformsToProtocol(aProtocol) {
                                                    instance?.setValue(subInstance, forKey: propertyElement.attributeForName(__kNameKey__).stringValue())
                                                }else{
                                                    fatalError("<\(propertyElement.attributeForName(__kRefKey__).stringValue())>不支持协议<\(propertyElement.attributeForName(__kProtocolNameKey__).stringValue())>")
                                                }
                                            }
                                            
                                        }
                                    }
                                }
                            }
                            
                        }
                        if let instance = instance{
                            if isSingleton(beanElement) {
                                singletons[String(instance)] = instance
                            }
                        }
                    }
                }
            case .GetBeanByProtocol:
                
                if beanElement.attributeForName(__kProtocolNameKey__) != nil {
                    if beanElement.attributeForName(__kProtocolNameKey__).stringValue() == name {
                        let aProtocol = swiftProtocolFromString(beanElement.attributeForName(__kProtocolNameKey__).stringValue())
                        instance = loadBean(id: beanElement.attributeForName(__kRefKey__).stringValue())
                        if let aProtocol = aProtocol {
                            if instance?.conformsToProtocol(aProtocol) == false {
                                fatalError("<\(beanElement.attributeForName(__kRefKey__).stringValue())>不支持协议<\(name)>")
                            }
                        }
                        
                    }
                }
            }
        }
        initializingClassPool.removeAll()
        return instance
    }
    
    func getBean(className className: String) -> AnyObject? {
        guard classCache[className] != nil else {
            fatalError("无法找到类<\(className)>")
        }
        return getBean(className, type: .GetBeanByClass)
    }
    
    func getBean(protocolName protocolName:String) -> AnyObject? {
        return getBean(protocolName, type: .GetBeanByProtocol)
    }
    
    // MARK: - 私有方法
    
    func loadBean(className className:String) -> AnyObject? {
        var bean: AnyObject?
        if let singletonBean = singletons[className]{
            bean = singletonBean
        }else{
            guard let beanFromCache = classCache[className] else {
                fatalError("<\(className)>未被加载至内存, 无法被实例化")
            }
            bean = (beanFromCache as! NSObject.Type).init()
        }
        TwinkleLog("装载<\(className)>")
        return bean
    }
    func loadBean(id id:String) -> AnyObject? {
        var bean: AnyObject?
        for beanElement in beanElements {
            if beanElement.attributeForName(__kIdKey__) != nil {
                if beanElement.attributeForName(__kIdKey__).stringValue() == id {
                    if beanElement.attributeForName(__kProtocolNameKey__) != nil//有protocolName
                    {
                        bean = getBean(protocolName: beanElement.attributeForName(__kProtocolNameKey__).stringValue())
                    }
                    else if beanElement.attributeForName(__kClassNameKey__) != nil//有className
                    {
                        bean = getBean(className: beanElement.attributeForName(__kClassNameKey__).stringValue())
                    }
                    else if beanElement.attributeForName(__kRefKey__) != nil//有ref
                    {
                        bean = loadBean(id: beanElement.attributeForName(__kRefKey__).stringValue())
                    }else
                    {
                        fatalError("找不到id=<\(id)>对象")
                    }
                }
            }
        }
        return bean;
    }
    func isSingleton(element:GDataXMLElement) -> Bool{
        if let node = element.attributeForName(__kScopeKey__) {
            if node.stringValue() == __kScopeTypeSingleton__ {
                return true
            }
            return false
        }
        return false
    }
}

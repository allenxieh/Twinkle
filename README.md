# Twinkle
---
简易的IoC, DI功能
#XML格式
---
```xml
<?xml version="1.0" encoding="UTF-8"?>

<root>
    <beans>
        
        <bean id="ImplTestProtocol" className="ImplTestProtocol" scope="singleton"/>
        
        <bean id="TestProtocol" protocolName="TestProtocol" ref="ImplTestProtocol" />
        
        <bean id="TestA" className="TestA" >
            <property name="testProtocl" ref = "TestProtocol"/>
        </bean>

    </beans>
</root>
```
**`root`->`beans` 作为根元素**

**`bean` beans下的元素**

`id` 全局唯一, `ref` 通过 `id` 寻找实例

`className` 类名

`protocolName` 协议名, 加入该属性, context在获取实例时会验证是否遵守了该协议

`scope` 作用域, 不写此属性默认每次生成新的实例, `scope="singleton"` 生成一个单例

**`property` bean的元素**

`className ` 类名

`name` 对象属性的名称, 通过name注入实例

`protocolName` 协议名, 加入该属性, context在获取实例时会验证是否遵守了该协议

`ref` 根据id寻找实例

依赖于
XML解析第三方框架:GDataXML http://code.google.com/p/gdata-objectivec-client/source/browse/trunk/Source/XMLSupport/

#举个栗子
---
###类注入
```swift
class ClassB: NSObject {
    func printLog() {
        print("this is ClassB")
    }
}
```
```swift
class ClassA: NSObject {
    var classB:ClassB?
}
```
XML配置
```XML
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <beans>
        <bean id="ClassA" className="ClassA" >
            <property name="classB" className="ClassB"/>
        </bean>
    </beans>
</root>
```
或者
```XML
<?xml version="1.0" encoding="UTF-8"?>

<root>
    <beans>
        <bean id="ClassA" className="ClassA" >
            <property name="classB" ref="ClassB"/>
        </bean>
        <bean id="ClassB" className="ClassB" />
    </beans>
</root>
```
代码
```swift
let classA:ClassA? = TwinkleApplicationContext.sharedInstance.getBean(className: "ClassA") as? ClassA
classA?.classB?.printLog()
```
控制台打印
```
this is classB
```
###协议注入
```swift
import Foundation

@objc public protocol Printable: NSObjectProtocol{
    func printTest()
}
```
```swift
class ImplPrintable: NSObject,Printable {
    func printLog() {
        print("this is ImplPrintable")
    }
}
```
```swift
class ClassA: NSObject {
    var printableClass:Printable?
}
```
```XML
<?xml version="1.0" encoding="UTF-8"?>

<root>
    <beans>
        <bean id="ImplPrintable" className="ImplPrintable"/>
        <bean id="Printable" protocolName="Printable" ref="ImplPrintable" />
        <bean id="ClassA" className="ClassA">
            <property name="printableClass" ref="Printable" />
        </bean>
    </beans>
</root>
```
代码
```swift
let classA:ClassA? = TwinkleApplicationContext.sharedInstance.getBean(className: "ClassA") as? ClassA
classA?.printableClass?.printLog()
```
控制台打印
```
this is ImplPrintable
```

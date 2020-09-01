//
//  ViewController.swift
//  JsonToClass
//
//  Created by 徐亚东 on 2019/6/6.
//  Copyright © 2019 xuyadong. All rights reserved.
//

import Cocoa

enum XDataType:String {
    case XTupleDic = "class"
    case XTupleArr = "array"
    case XNSInteger = "NSInteger"
    case XString = "String"
    case XCGFloat = "CGFloat"
    case XBool = "Bool"
    case XNull = "AnyObject"
    case XUnknown = "UnknownType"
}

class ViewController: NSViewController {
    var modelsArr:[String:[String]] = [String:[String]]()
    var errorsArr:[String] = [String]()
    var classStrArr = [Int:String]()
    var s1Count = 0,s2Count = 0,s3Count = 0,s4Count = 0,maxTier = 0
    var leftStr = [Int:String]()
    var rightStr = [Int:String]()
    var strIndexArr = [String.Index]()
    
    var symbolsIndex = [String:[Range<String.Index>]]()
    var arrDictionary = [String]()
    var arrModelStr = [String]()
    
    
    @IBOutlet weak var vTextView: NSScrollView!
    
    @IBAction func checkAction(_ sender: Any) {
        self.checkString()
    }
    
    @IBOutlet weak var vShowClassView: NSScrollView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        
        }
    }

    private func checkString(){
        s1Count = 0
        s2Count = 0
        s3Count = 0
        s4Count = 0
        maxTier = 0
        self.modelsArr.removeAll()
        self.errorsArr.removeAll()
        self.classStrArr.removeAll()
        self.leftStr.removeAll()
        self.rightStr.removeAll()
        
        self.symbolsIndex.removeAll()
        self.arrDictionary.removeAll()
        self.arrModelStr.removeAll()
        
        let myTextView:NSTextView = self.vTextView.documentView as! NSTextView
        var myText:String = myTextView.string
        myText = self.clearBlank(myText)//删除空格字符
        myText = self.clearEnter(myText)//删除换行符
        myText = self.clearTab(myText)//删除跳表符
        
        self.getTier(myText,myText.startIndex..<myText.endIndex)
        var classStr = ""
        self.arrModelStr.reverse()
        for value in self.arrModelStr{
            classStr.append(value)
        }
        let showTextView:NSTextView = self.vShowClassView.documentView as! NSTextView
        showTextView.string = classStr
        print("error = \(errorsArr)")
    }
}

// MARK: - func
extension ViewController{
    /// 解析json数据的层数 (比如字典里面不包含字典则为1层，字典里面包含字典则为2层)
    ///
    /// - Parameter text: json字符串
    private func getTier(_ text:String,_ searchRange:Range<String.Index>){
        var newText = text
        let s1 = "{",s2 = "}" ,s3 = "[",s4 = "]"
        let temp = newText.rangeTupleChars([s1,s2,s3,s4],searchRange)
        guard temp.0 != nil else {
            return
        }
        switch temp.0 {
        case s1:
            s1Count += 1
            break
        case s2:
            s2Count += 1
            break
        case s3:
            s3Count += 1
            break
        case s4:
            s4Count += 1
            break
        default:
            break
        }
        var left  = self.symbolsIndex[s1]
        var right = self.symbolsIndex[s2]
        if left == nil{
            self.symbolsIndex[s1] = [Range<String.Index>]()
        }
        if right == nil{
            self.symbolsIndex[s2] = [Range<String.Index>]()
        }
        self.symbolsIndex[temp.0!]?.append(temp.1!)
         left  = self.symbolsIndex[s1]
         right = self.symbolsIndex[s2]
        if temp.0! == s2{
            if right?.count ?? 0 > 0{
                let leftRange = left!.last!
                let rightRange = right!.last!
                let item = text[leftRange.upperBound..<rightRange.lowerBound]
                let itemStr = String(item)
                let temp = self.analysisDictionary("{" + itemStr + "}")
                let classStr = self.createClassString(temp.membersNameArr,temp.membersTypeArr,temp.membersTypeStrArr)
                if !classStr.isEmpty{
                    self.arrModelStr.append(classStr)
                }
                self.arrDictionary.append(String(item))
                self.symbolsIndex[s1]?.removeLast()
            }
        }
          self.getTier(text,temp.1!.upperBound..<text.endIndex)
    }
    
    /// 清空空格字符
    ///
    /// - Parameter text: text
    /// - Returns: no blank text
    private func clearBlank(_ text:String)->String{
        var newText = text
        newText = newText.replacingOccurrences(of: " ", with: "")
        return newText
    }
    
    
    /// 清空回车字符
    ///
    /// - Parameter text: text
    /// - Returns: no enter text
    private func clearEnter(_ text:String)->String{
        var newText = text
        newText = newText.replacingOccurrences(of: "\n", with: "")
        return newText
    }
    
    /// 清空跳格符
    ///
    /// - Parameter text: text
    /// - Returns: no enter text
    private func clearTab(_ text:String)->String{
        var newText = text
        newText = newText.replacingOccurrences(of: "\t", with: "")
        return newText
    }
    
    
    /// 将字典拆分成key数组和value数组以及对应的类型数组
    ///
    /// - Parameter text: text
    /// - Returns: [key] and [value] and [type]
    private func analysisDictionary(_ text:String)->( membersNameArr:[String],membersValueArr:[String],membersTypeArr:[XDataType],membersTypeStrArr:[String]){
        var newText  = text
        newText = self.getSubStringInSymbol(text, "{", "}")
        
        var membersNameArr = [String]()//存放key
        var membersValueArr = [String]()//存放value
        var membersTypeArr = [XDataType]()//存放类型
        var membersTypeStrArr = [String]()//存放类型对应的字符串
        
        var zhongkuohao :Int = 0
        var dakuohao :Int = 0
        var yinhao : Int = 0
        
        let items = newText.split { (item) -> Bool in
            if item == ","{
                if dakuohao == 0 && zhongkuohao == 0 && yinhao%2 == 0{
                    return true
                }
                return false
            }
            if item == "{"{
                dakuohao = dakuohao + 1
            }
            if item == "}"{
                dakuohao = dakuohao - 1
            }
            if item == "["{
                zhongkuohao = zhongkuohao + 1
            }
            if item == "]"{
                zhongkuohao = zhongkuohao - 1
            }
            if item == "\""{
                yinhao = yinhao + 1
            }
            return false
        }
        
        for value in items{
            let subItems = value.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)//将每一项中的key与value拆分出来
            guard subItems.count == 2 else{
                return([String](),[String](),[XDataType](),[String]())
            }
            let className = self.getSubStringInSymbol(String(subItems.first!), "\"", "\"")//获取key
            
            let classValue = String(subItems.last!)//获取值
            let type = self.judgeType(classValue)//判断值的类型
            if  type == XDataType.XTupleArr{ //值是数组类型
               let temp = self.analysisArray(classValue)
                if temp.0 == XDataType.XTupleArr{
                    let classStr = temp.1
                    membersTypeStrArr.append(classStr)
                }else if temp.0 == XDataType.XTupleDic{
                    let classStr = temp.1
                    membersTypeStrArr.append(classStr)
                }else if temp.0 == XDataType.XUnknown{
                    membersTypeStrArr.append(temp.1)
                }else{
                    membersTypeStrArr.append(temp.0.rawValue)
                }
            }else if type == XDataType.XTupleDic{ //值是字典类型
                let temp = self.analysisDictionary(classValue)
                let classStr = self.getModelName(temp.membersNameArr).0
                membersTypeStrArr.append(classStr)
             }else if type == XDataType.XUnknown{// 值是未知类型
                
             }else{//值是基本类型
                
            }
            
            membersNameArr.append(className)
            membersValueArr.append(classValue)
            membersTypeArr.append(type)
            
            if type != XDataType.XTupleDic && type != XDataType.XTupleArr {
                 membersTypeStrArr.append(type.rawValue)
            }
        }
        let tempArr = [membersNameArr,membersValueArr,membersTypeArr,membersTypeStrArr] as? [[AnyObject]]
        for item in tempArr!{
            if item.count != tempArr![0].count{
                print("解析错误")
            }
        }
        return(membersNameArr,membersValueArr,membersTypeArr,membersTypeStrArr)
    }
    
    
    private func analysisArray(_ text:String) ->(XDataType,String){//["a","b","c"]
        var newText  = text
        newText.remove(at: newText.startIndex)
        newText.remove(at: newText.index(newText.endIndex, offsetBy: .init(-1)))
        
        var zhongkuohao :Int = 0
        var dakuohao :Int = 0
        var yinhao : Int = 0
        
        let items = newText.split { (item) -> Bool in
            if item == ","{
                if dakuohao == 0 && zhongkuohao == 0 && yinhao%2 == 0{
                    return true
                }
                return false
            }
            if item == "{"{
                dakuohao = dakuohao + 1
            }
            if item == "}"{
                dakuohao = dakuohao - 1
            }
            if item == "["{
                zhongkuohao = zhongkuohao + 1
            }
            if item == "]"{
                zhongkuohao = zhongkuohao - 1
            }
            if item == "\""{
                yinhao = yinhao + 1
            }
            return false
        }
        
        guard items.count != 0 else{
            self.errorsArr.append("数组为空")
            return (XDataType.XUnknown,"数组为空")
        }
        
        var type = XDataType.XUnknown
        var modelName = ""
        for item in items{
          type = self.judgeType(String(item))
            if type == .XTupleArr{
               modelName = "Anyobject"
            }else if type == .XTupleDic{
               let temp = self.analysisDictionary(String(item))
                modelName = self.getModelName(temp.membersNameArr).0
            }else if type == .XUnknown{
                modelName = "error"
            }else {
                modelName = type.rawValue
            }
            break
        }
        return (type,modelName)
    }
    
    /// 返回给定两个符号的中间的字符串内容(查找第一个符号的时候是顺序查找第一次出现的地方，查找第二个字符的时候是倒序查找第一次出现的位置)
    ///
    /// - Parameters:
    ///   - text: 原始的字符串
    ///   - symbolOne: 符号1
    ///   - symbolTwo: 符号2
    /// - Returns: 中间的内容
    private func getSubStringInSymbol(_ text:String,_ symbolOne:String,_ symbolTwo:String) -> String{
        let newText = text
        guard let range1 = newText.range(of: symbolOne) else {
            return ""
        }
        guard let range2 = newText.range(of: symbolTwo, options: .init(arrayLiteral: .backwards), range: newText.startIndex..<newText.endIndex, locale: nil) else {
            return ""
        }
        
        let aa =  String(newText[range1.upperBound..<range2.lowerBound])
        return aa
    }
    
    
    fileprivate func getInitValueWithType(_ text : String)->AnyObject{
        var temp : AnyObject?
        switch text {
        case "String":
            temp = "\"\"" as AnyObject
            break
        case "NSInteger":
            temp = 0 as AnyObject
            break
        case "CGFloat":
            temp = 0.0 as AnyObject
            break
        case "Bool":
            temp = "false" as AnyObject
            break
        case "null":
            temp = "" as AnyObject
            break
        default:
            temp = "" as AnyObject
            break
        }
        return temp as AnyObject
    }
    
    /// 根据key所对应的value值类型判断原始数据类型 (字符串，数字类型，bool类型,null类型等)
    ///
    /// - Parameter text: text
    /// - Returns: 类型
    private func judgeType(_ text:String)->XDataType{
        var type = XDataType.XUnknown
        let firstTemp = String(text.first!)
        let lastTemp = String(text.last!)
        
        if firstTemp == "{" && lastTemp == "}"{//字典
            type = .XTupleDic
        }else if firstTemp == "[" && lastTemp == "]"{//数组
            type = .XTupleArr
        }else if firstTemp == "\"" && lastTemp == "\""{//字符串
            type = .XString
        }else if text == "true" || text == "false"{//Bool值
            type = .XBool
        }else if text == "null"{ //null默认为字符串类型
            type = .XString
        }else if text.contains(where: { (element) -> Bool in
            if  element.isNumber{
                return true
            }else{
                return false
            }
        }){//是数字类型
            type = .XNSInteger
            if text.contains("."){
                type = .XCGFloat
            }
        }else{//未识别的类型
            print("error = \(text)")
            self.errorsArr.append(text)
        }
        if type == XDataType.XUnknown{
            self.errorsArr.append(text)
        }
        return type
    }
    
    private func createClassString(_ membersName:[String],_ membersType:[XDataType],_ membersTypeStr:[String]) -> String{
        let temp = self.getModelName(membersName)
        if temp.1 == false{
            return ""
        }
        var classStr = "@objcMembers class \(temp.0) : NSObject{\n"
        for index in 0..<membersType.count{
            let memberName = membersName[index]
            let memberType = membersType[index]
            let memberTypeStr = membersTypeStr[index]
            var newMember = ""
            if memberType == XDataType.XTupleDic{
                 newMember = "var    \(memberName) : \(memberTypeStr) =  \(memberTypeStr)()\n"
            }else if memberType == XDataType.XTupleArr{
                 newMember = "var    \(memberName) : [\(memberTypeStr)] =  [\(memberTypeStr)]()\n"
            }else if memberType == XDataType.XUnknown {
                newMember = "var    \(memberName) : \(memberType.rawValue) = \(self.getInitValueWithType(memberType.rawValue))\n"
            }else{
                newMember = "var    \(memberName) : \(memberType.rawValue) = \(self.getInitValueWithType(memberType.rawValue))\n"
            }
            classStr.append(newMember)
        }
        classStr.append("}\n\n")
        return classStr
    }
    
    
    
    /// 根据字典的key来获取是否存在对应的model
    ///
    /// - Parameter membersName: 字典的key数组
    /// - Returns: 自动生成的model的名称以及是否是新的model
    private func getModelName(_ membersName:[String])->(String,Bool){
        var modelName = ""
        var isNewModel = true
        for item in self.modelsArr{
            if item.value.elementsEqual(membersName){
                modelName = item.key
                isNewModel = false
                break
            }
        }
        
        if modelName.isEmpty{
            if self.modelsArr.count == 0{
                self.modelsArr["1"] = membersName
                modelName = "1"
            }else{
                let keyInts = self.modelsArr.keys.map { (item) -> Int in
                    let temp = Int(item) ?? 0
                    return temp
                }
                modelName = String(keyInts.max()! + 1)
                self.modelsArr[modelName] = membersName
            }
        }
        modelName = "model\(modelName)"
        return (modelName,isNewModel)
    }
}

extension String{
    func rangeTupleChars(_ tuple:[String],_ searchRange: Range<String.Index>) ->(String?,Range<String.Index>?){
        var minIndexValue :String?
        var minRange : Range<String.Index>?
        for value in tuple{
            let temp = self.range(of: value, options: .init(), range: searchRange, locale: nil)
            guard temp != nil else{continue}
            if  minRange == nil{
                minIndexValue = value
                minRange = temp!
            }else{
                let tempBool = minRange!.lowerBound < temp!.lowerBound
                if !tempBool {
                    minRange = temp
                    minIndexValue = value
                }
            }
        }
        return(minIndexValue,minRange)
    }
}

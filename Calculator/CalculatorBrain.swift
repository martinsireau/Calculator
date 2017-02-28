//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by martin sireau on 07/01/17.
//  Copyright © 2017 p0is0n1vy. All rights reserved.
//

import Foundation

func genRandomNumber() -> Double{
    return (Double(arc4random()) / Double(UINT32_MAX))
}

class CalculatorBrain {
    
    private var accumulator = 0.0
    private var internalProgram = [AnyObject]()
    var isPartialResult : Bool{
        return pending != nil
    }
    var description = ""
    var arrayDesc = [""]
    var constantHit = false
    
    var M : Double{
        get {
            if (variableValues["M"] == nil){
                variableValues["M"] = 0.0
            }
            return variableValues["M"]!
        } set {
            variableValues["M"] = newValue
        }
    }
    
    var variableValues: Dictionary<String, Double> = [:]
    
    func setOperand(variableName: String){
        performOperation(symbol: variableName)
    }
    
    func setOperand(operand: Double) {
        if isPartialResult == false {arrayDesc.removeAll()}
        accumulator = operand
        internalProgram.append(operand as AnyObject)
    }
    
    private var operations: Dictionary<String, Operation> = [
        "π" : Operation.Constant(M_PI),
        "e" : Operation.Constant(M_E),
        "rand": Operation.Rand,
        "±" : Operation.UnaryOperation({-$0}),
        "√" : Operation.UnaryOperation(sqrt),
        "sin": Operation.UnaryOperation({sin($0 * M_PI / 180)}),
        "cos" : Operation.UnaryOperation({cos($0 * M_PI / 180)}),
        "tan": Operation.UnaryOperation({tan($0 * M_PI / 180)}),
        "×" : Operation.BinaryOperation({ $0 * $1 }),
        "÷" : Operation.BinaryOperation({ $0 / $1 }),
        "+" : Operation.BinaryOperation({ $0 + $1 }),
        "-" : Operation.BinaryOperation({ $0 - $1 }),
        "=" : Operation.Equals,
        "C" : Operation.Clear,
        "M" : Operation.Var
    ]
    
    private enum Operation {
        case Constant(Double)
        case UnaryOperation((Double) -> Double)
        case BinaryOperation((Double, Double) -> Double)
        case Equals
        case Clear
        case Rand
        case Var
    }
    
    private func smallFloatingNumber(myNumber: Double)->String{
        if myNumber == 0.0 { return "0"}
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        return (formatter.string(for: myNumber))!
    }
    
    func performOperation(symbol: String) {
        internalProgram.append(symbol as AnyObject)
        if let operation = operations[symbol]{
            switch operation {
            case .Constant(let value):
                accumulator = value
                forConstant(symbol: symbol)
            case .UnaryOperation(let function):
                forUnaryOperation(symbol: symbol)
                accumulator = function(accumulator)
            case .BinaryOperation(let function):
                forBinaryOperation(symbol: symbol)
                executePendingBinaryOperation()
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
            case .Equals:
                forBinaryOperation(symbol: "")
                executePendingBinaryOperation()
            case .Rand:
                accumulator = genRandomNumber()
                forConstant(symbol: ("0\(smallFloatingNumber(myNumber: accumulator))"))
            case .Clear:
                clear()
            case .Var:
                accumulator = M
                forConstant(symbol: symbol)
            }
        }
        description = arrayDesc.joined()
    }
    
    private func checkLastElem(symbol: String){
        if let lastElem = arrayDesc.last,
            lastElem.characters.count >= 1,
            lastElem.substring(from: lastElem.index(lastElem.endIndex, offsetBy: -1)) == ")"{
            arrayDesc.removeLast()
        }
    }
    
    private func forConstant(symbol: String){
        if isPartialResult && constantHit == false {
            checkLastElem(symbol: symbol)
            arrayDesc.append(symbol)
        } else {
            if !arrayDesc.isEmpty{
                arrayDesc.removeLast()
            }
            arrayDesc.append(symbol)
        }
        constantHit = true
    }
    
    private func forUnaryOperation(symbol: String){
        var saveLastChar = ""
        if isPartialResult == false && !arrayDesc.isEmpty{
            arrayDesc.insert(symbol + "(", at: 0)
            arrayDesc.append(")")
        } else if constantHit{
            saveLastChar = arrayDesc.last!
            arrayDesc.removeLast()
            arrayDesc.append("\(symbol)(\(saveLastChar))")
        } else {
            checkLastElem(symbol: symbol)
            arrayDesc.append("\(symbol)(\(smallFloatingNumber(myNumber: accumulator)))")
        }
        constantHit = false
    }
    
    private func forBinaryOperation(symbol: String){
        if !arrayDesc.isEmpty,
            let lastElem = arrayDesc.last,
            lastElem.characters.count >= 1,
            lastElem.substring(from: lastElem.index(lastElem.endIndex, offsetBy: -1)) == ")"
            {}
        else if (isPartialResult || arrayDesc.isEmpty) && constantHit == false{
            arrayDesc.append("\(smallFloatingNumber(myNumber: accumulator))")
        }
        arrayDesc.append("\(symbol)")
        constantHit = false
    }
    
    private func executePendingBinaryOperation(){
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            pending = nil
        }
    }
    
    private var pending: PendingBinaryOperationInfo?
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
    }
    
    func dropLastInternalProg(){
        if !internalProgram.isEmpty{
            internalProgram.removeLast()
        }
    }
    
    typealias PropertyList = AnyObject
    
    var program: PropertyList{
        get {
            return internalProgram as CalculatorBrain.PropertyList
        }
        set {
            clear()
            if let arrayOfOps = newValue as? [AnyObject] {
                for op in arrayOfOps {
                    if let operand = op as? Double{
                        setOperand(operand: operand)
                    } else if let operation = op as? String {
                        performOperation(symbol: operation)
                    }
                }
            }
        }
    }
    
    private func clear() {
        accumulator = 0.0
        pending = nil
        constantHit = false
        internalProgram.removeAll()
        arrayDesc.removeAll()
    }
    
    var result: Double {
        get {
            return accumulator
        }
    }
}

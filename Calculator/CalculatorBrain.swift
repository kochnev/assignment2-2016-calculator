//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by  alexander on 04.05.16.
//  Copyright © 2016  alexander. All rights reserved.
//

import Foundation


class CalculatorBrain
{
    
    let formatter:NSNumberFormatter = {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .DecimalStyle
        formatter.maximumFractionDigits = 6
        formatter.notANumberSymbol = "Error"
        formatter.groupingSeparator = " "
        formatter.locale = NSLocale.currentLocale()
        return formatter
        
    } ()
    
    var isPartialResult: Bool {
        get {
            return pending != nil
        }
    }
    
    var description: String {
        get {
            if pending == nil {
                return descriptionAccumulator
            }
            else {
                return pending!.descriptionBinaryFunction(pending!.descriptionFirstOperand, (descriptionAccumulator != pending!.descriptionFirstOperand ?descriptionAccumulator : "")
                )
            }
            
        }
    }
    
    private var internalProgram = [AnyObject]()
    
    private var accumulator = 0.0
    private var descriptionAccumulator = "0" {
        didSet {
            if pending == nil {
                currentPrecedence = Int.max
            }
        }
    }
    private var currentPrecedence = Int.max
    
    private var operations: Dictionary<String, Operation> = [
        "rand": Operation.NullaryOperation(drand48,"rand()"),
        "π" : Operation.Constant(M_PI),// M_PI,
        "e" : Operation.Constant(M_E),// M_E,
        "√" : Operation.UnaryOperation(sqrt, { "√(" + $0 + ")" }),// sqrt,
        "cos" : Operation.UnaryOperation(cos, { "cos(" + $0 + ")"}),// cos
        "sin" : Operation.UnaryOperation(sin, { "sin(" + $0 + ")"}),
        "㏑" : Operation.UnaryOperation(log, { "ln(" + $0 + ")"}),
        "∛" : Operation.UnaryOperation(cbrt, { "∛(" + $0 + ")"}),
        "x²" : Operation.UnaryOperation({pow($0, 2)}, {$0 + "²"}),
        "x³" : Operation.UnaryOperation({pow($0, 3)}, {$0 + "³"}),
        "±" :  Operation.UnaryOperation({-$0},{"-(" + $0 + ")"}),
        "×" : Operation.BinaryOperation( * , { $0 + "*" + $1 }, 1),
        "÷" : Operation.BinaryOperation( /, { $0 + "/" + $1 }, 1),
        "+" : Operation.BinaryOperation( +, { $0 + "+" + $1 }, 0),
        "−" : Operation.BinaryOperation( -, { $0 + "-" + $1 }, 0),
        "=" : Operation.Equals
    ]
    
    func setOperand(operand: Double) {
        accumulator = operand
        
        internalProgram.append(operand)
       
        descriptionAccumulator = formatter.stringFromNumber(operand)!
    }
    
    func setOperand(variableName: String) {
        if variableValues[variableName] == nil {
            operations[variableName] = Operation.Variable
        }
        
        performOperation(variableName)
    }
    
    var variableValues = [String: Double]() {
        didSet {
            program = internalProgram
        }
            
    }
    
    func performOperation(symbol: String) {
        internalProgram.append(symbol)
        if let operation = operations[symbol] {
            switch operation {
            case .Variable:
                accumulator = variableValues[symbol] ?? 0.0
                descriptionAccumulator = symbol
            case .NullaryOperation(let function, let descriptionFunction):
                accumulator = function()
                descriptionAccumulator = descriptionFunction
            case .Constant(let associatedValue):
                accumulator = associatedValue
                descriptionAccumulator = symbol
            case .UnaryOperation(let function, let descriptionFunction):
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .BinaryOperation(let function, let descriptionFunction, let precedence):
                pendingBinaryOperation()
                if currentPrecedence<precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator, descriptionBinaryFunction: descriptionFunction, descriptionFirstOperand: descriptionAccumulator)
            case .Equals:
                pendingBinaryOperation()
            }
            
        }
        
    }
    
    typealias PropertyList = AnyObject
    var program: PropertyList
    {
        get {
            return internalProgram
        }
        set {
            if let arrayOfOps = newValue as?[AnyObject] {
                for op in arrayOfOps {
                    if let operand = op as? Double {
                        setOperand(operand)
                    }
                    else if let operation = op as? String {
                             performOperation(operation)
                    }
                }
            }
        }
    }
    func undo() {
        guard !internalProgram.isEmpty else { return }
        internalProgram.removeLast()
        program = internalProgram
    }
    func clear()
    {
        accumulator = 0.0
        descriptionAccumulator = " "
        pending = nil
        internalProgram.removeAll()
        currentPrecedence = Int.max
    }
    
    func clearVariables() {
        variableValues.removeAll()
    }
    
    func getVariable(symbol: String) -> Double? {
        return variableValues[symbol]
    }
    func setVariable(symbol: String, variableValue: Double) {
         variableValues[symbol] = variableValue
    }
    
    private func pendingBinaryOperation()
    {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            descriptionAccumulator = pending!.descriptionBinaryFunction(pending!.descriptionFirstOperand, descriptionAccumulator)
            pending = nil
        }
    }
    
    private var pending: PendingBinaryOperationInfo?
    
    private enum Operation {
        case Variable
        case NullaryOperation(()-> Double, String)
        case Constant(Double)
        case UnaryOperation((Double) -> Double, (String) -> String)
        case BinaryOperation((Double, Double) -> Double, (String, String) -> String, Int)
        case Equals
        
    }
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionBinaryFunction: (String, String) -> String
        var descriptionFirstOperand: String
    }
    
    var result: Double {
        get {
            return accumulator
        }
        
    }
    
}

let formatter:NSNumberFormatter = {
    let formatter = NSNumberFormatter()
    formatter.numberStyle = .DecimalStyle
    formatter.maximumFractionDigits = 6
    formatter.notANumberSymbol = "Error"
    formatter.groupingSeparator = " "
    formatter.locale = NSLocale.currentLocale()
    return formatter
    
} ()
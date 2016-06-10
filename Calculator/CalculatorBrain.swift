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
    private var errorDetails: String?
    
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
        "√" : Operation.UnaryOperation(sqrt, { "√(" + $0 + ")" }, { $0<0 ? "√ отриц. чисал" : nil}),// sqrt,
        "cos" : Operation.UnaryOperation(cos, { "cos(" + $0 + ")"}, nil),// cos
        "sin" : Operation.UnaryOperation(sin, { "sin(" + $0 + ")"}, nil),
        "㏑" : Operation.UnaryOperation(log, { "ln(" + $0 + ")"},{ $0<0 ? "ln отриц. чисал" : nil}),
        "∛" : Operation.UnaryOperation(cbrt, { "∛(" + $0 + ")"}, nil),
        "x²" : Operation.UnaryOperation({pow($0, 2)}, {$0 + "²"}, nil),
        "x³" : Operation.UnaryOperation({pow($0, 3)}, {$0 + "³"}, nil),
        "±" :  Operation.UnaryOperation({-$0},{"-(" + $0 + ")"}, nil),
        "×" : Operation.BinaryOperation( * , { $0 + "*" + $1 }, 1, nil),
        "÷" : Operation.BinaryOperation( /, { $0 + "/" + $1 }, 1, { $1==0 ? "деление на ноль" : nil}),
        "+" : Operation.BinaryOperation( +, { $0 + "+" + $1 }, 0, nil),
        "−" : Operation.BinaryOperation( -, { $0 + "-" + $1 }, 0, nil),
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
            case .UnaryOperation(let function, let descriptionFunction, let validator):
                errorDetails = validator?(accumulator)
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .BinaryOperation(let function, let descriptionFunction, let precedence, let validator):
                pendingBinaryOperation()
                if currentPrecedence<precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                currentPrecedence = precedence
                pending = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator, descriptionBinaryFunction: descriptionFunction, descriptionFirstOperand: descriptionAccumulator,
                    validator: validator)
            case .Equals:
                pendingBinaryOperation()
            }
            
        }
        
    }
    
    private func pendingBinaryOperation()
    {
        if pending != nil {
            errorDetails = pending!.validator?(pending!.firstOperand, accumulator)
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            descriptionAccumulator = pending!.descriptionBinaryFunction(pending!.descriptionFirstOperand, descriptionAccumulator)
            pending = nil
        }
    }
    
  
    
    
    typealias PropertyList = AnyObject
    var program: PropertyList
    {
        get {
            return internalProgram
        }
        set {
            clear()
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
        errorDetails = nil
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
    
   
    
    private var pending: PendingBinaryOperationInfo?
    
    private enum Operation {
        case Variable
        case NullaryOperation(()-> Double, String)
        case Constant(Double)
        case UnaryOperation((Double) -> Double, (String) -> String, ((Double) -> String?)?)
        case BinaryOperation((Double, Double) -> Double, (String, String) -> String, Int, ((Double, Double) -> String?)? )
        case Equals
        
    }
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionBinaryFunction: (String, String) -> String
        var descriptionFirstOperand: String
        var validator: ((Double, Double) -> String?)?
    }
    
    var result: (Double, String?) {
        get {
            return (accumulator, errorDetails)
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
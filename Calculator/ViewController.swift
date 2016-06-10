//
//  ViewController.swift
//  Calculator
//
//  Created by  alexander on 04.05.16.
//  Copyright © 2016  alexander. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet private weak var display: UILabel!
    @IBOutlet weak var history: UILabel!
    
    private var isUserInMiddle = false
   
    @IBAction func clearAll(sender: UIButton) {
        brain.clear()
        brain.clearVariables()
        displayValue = nil
    }
  
   
    @IBAction func undo() {
        if isUserInMiddle {
            if (display.text!.characters.count == 1) {
                display.text = "0"
                isUserInMiddle = false
            }
            else {
                display.text!.removeAtIndex(display.text!.endIndex.predecessor())
            }
        }
        else {
            brain.undo()
            resultValue = brain.result
        }

    }
    @IBAction func backspace() {
       
    }
    @IBAction func setVariable(sender: UIButton) {
        brain.setOperand(sender.currentTitle!)
        resultValue = brain.result
    }
    
    @IBAction func setVariableValue(sender: UIButton) {
        isUserInMiddle = false
        let symbol = String((sender.currentTitle!).characters.dropFirst())
        if let value = displayValue {
            brain.setVariable(symbol, variableValue: value)
            resultValue = brain.result
        }
    }
    @IBAction private func touchDigit(sender: UIButton) {
        
        var digit = sender.currentTitle!
        
        if isUserInMiddle
        {
            let currenTextInDisplay = display.text!
            
            if currenTextInDisplay.containsString(".") && digit == "." {
                 digit = ""
            }
            display.text = currenTextInDisplay + digit
            
        }
        else
        {
            display.text = (digit == ".") ? "0." : digit
        }
        
        isUserInMiddle = true
    }
    
    private var displayValue: Double?
        {
            get {
            if let text = display.text,
                value = formatter.numberFromString(text)?.doubleValue {
                return value
            }
            return nil
        }
        set {
            if let value = newValue {
                display.text = formatter.stringFromNumber(value)
                history.text = brain.description + (brain.isPartialResult ? " …" : " =")
            } else {
                display.text = "0"
                history.text = " "
                isUserInMiddle = false
            }
        }
        
    }
    
    private var brain = CalculatorBrain()
    
    private var resultValue: (Double, String?) = (0.0 , nil) {
        didSet {
            switch resultValue {
            case (_, nil): displayValue = resultValue.0
            case (_, let error):
                display.text = error
                history.text = brain.description + (brain.isPartialResult ? " …" : " =")
                isUserInMiddle = false
            }
            
        }
    }
    
    @IBAction private func performOperation(sender: UIButton) {
        
        if isUserInMiddle {
            brain.setOperand(displayValue!)
            isUserInMiddle = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        
        resultValue = brain.result
       
        
    }
    
}


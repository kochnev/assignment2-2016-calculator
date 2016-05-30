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
        displayValue = brain.result
        history.text = brain.description
        isUserInMiddle = false
        
    }
  
   
    @IBAction func undo() {
        if isUserInMiddle {
            backspace()
        }
        else {
            brain.undo()
            savedProgram = brain.program
            brain.program = savedProgram!
            displayValue = brain.result
        }

    }
    @IBAction func backspace() {
        if (display.text!.characters.count == 1) {
            display.text = "0"
            isUserInMiddle = false
        }
        else {
            display.text!.removeAtIndex(display.text!.endIndex.predecessor())
        }

    }
    private var savedProgram: CalculatorBrain.PropertyList?
    
    @IBAction func save() {
        savedProgram = brain.program
    }
    @IBAction func restore() {
        if savedProgram != nil {
            brain.program = savedProgram!
            displayValue = brain.result
           isUserInMiddle = false
            
        }
    }
    @IBAction func setVariable(sender: UIButton) {
        brain.setOperand(sender.currentTitle!)
        displayValue = brain.result
    }
    
    @IBAction func setVariableValue(sender: UIButton) {
        brain.variableValues["M"] = displayValue
        savedProgram = brain.program
         brain.program = savedProgram!
         displayValue = brain.result
        isUserInMiddle = false
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
    
    private var displayValue: Double
        {
        get {
            return Double(display.text!)!
        }
        set {
            let decimalFormater = NSNumberFormatter()
            decimalFormater.numberStyle = .DecimalStyle
            decimalFormater.maximumFractionDigits = 6
            display.text = decimalFormater.stringFromNumber(newValue)!
            history.text = brain.description + (brain.isPartialResult ? "…" : "=")
        }
        
    }
    
    private var brain = CalculatorBrain()
    
    @IBAction private func performOperation(sender: UIButton) {
        
        if isUserInMiddle {
            brain.setOperand(displayValue)
            isUserInMiddle = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        
        displayValue = brain.result
        
    }
    
}


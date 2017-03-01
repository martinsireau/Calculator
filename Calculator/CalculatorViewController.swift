//
//  ViewController.swift
//  Calculator
//
//  Created by martin sireau on 06/01/17.
//  Copyright © 2017 p0is0n1vy. All rights reserved.
//

import UIKit

class CalculatorViewController: UIViewController {
    
    @IBOutlet weak var myDescription: UILabel!
    @IBOutlet private weak var myResult: UILabel!
    
    private var formatter = NumberFormatter()
    private var userIsInTheMiddleOfTyping = false
    private var brain = CalculatorBrain()
    private var scndSavedProgram: CalculatorBrain.PropertyList?
    var savedProgram: CalculatorBrain.PropertyList?
    private var forHistory = [String]()
    
    @IBAction private func digitTapped(_ sender: UIButton) {
        let digit = sender.currentTitle!
        let textCurrentlyInDisplay = myResult.text
        
        if userIsInTheMiddleOfTyping {
            if myResult.text!.contains(".") == false || digit != "."{
                myResult.text = textCurrentlyInDisplay! + digit
            }
        } else {
            myResult.text = digit
            userIsInTheMiddleOfTyping = true
        }
    }
    
    @IBAction func save() {
        savedProgram = brain.program
    }
    
    @IBAction func restore() {
        if savedProgram != nil {
            brain.program = savedProgram!
            displayValue = brain.result
            setDescriptionAndResultDisplay()
        }
    }
    
    @IBAction func BackSpace(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping {
            if var text = myResult.text {
                text.remove(at: text.index(before: text.endIndex))
                if text.isEmpty {
                    text = "0"
                    userIsInTheMiddleOfTyping = false
                }
                myResult.text = text
            }
        } else {
            brain.dropLastInternalProg()
            refreshBrainProgram()
        }
    }
    
    private var displayValue : Double? {
        get {
            return Double(myResult.text!)!
        } set {
            myResult.text = formatter.string(for: newValue)
        }
    }
    
    @IBAction func useValue() {
        displayValue = brain.M
        brain.setOperand(variableName: "M")
    }
    
    @IBAction func storeValue() {
        brain.M = displayValue!
        userIsInTheMiddleOfTyping = false
        refreshBrainProgram()
    }
    
    @IBAction private func performingAction(_ sender: UIButton) {
        if userIsInTheMiddleOfTyping && myResult.text! != "."{
            brain.setOperand(operand: displayValue!)
            userIsInTheMiddleOfTyping = false
        }
        if let mathematicalSymbol = sender.currentTitle{
            brain.performOperation(symbol: mathematicalSymbol)
            if mathematicalSymbol == "C"{
                brain.variableValues.removeAll()
            }
        }
        setDescriptionAndResultDisplay()
    }
    
    private func setDescriptionAndResultDisplay() {
        displayValue = brain.result
        if brain.description != "" {
            var cpDescription = brain.description
            cpDescription += brain.isPartialResult ? "..." : "="
            myDescription.text = cpDescription
        } else {
            myDescription.text = " "
        }
    }
    
    private func refreshBrainProgram(){
        scndSavedProgram = brain.program
        brain.program = scndSavedProgram!
        displayValue = brain.result
              setDescriptionAndResultDisplay()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        navigationController?.isNavigationBarHidden = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
    }
    
}

//
//  ViewController.swift
//  CoinbasePriceWatcher
//
//  Created by Kyle on 5/6/17.
//  Copyright © 2017 Brennan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    let BTC = 0
    let ETH = 1
    let currencyKey = "CurrencySettingKey"

    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var currPicker: UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        currPicker.delegate = self
        currPicker.dataSource = self

        let defaults = UserDefaults.standard
        let defaultCurr = defaults.integer(forKey: currencyKey)
        currPicker.selectRow(defaultCurr, inComponent: 0, animated: false)
        refreshData(forCurrency: defaultCurr)
    }

    private func refreshData(forCurrency curr: Int) {
        let requestURL: URL
        switch curr {
        case BTC:
            requestURL = URL(string: "https://coinbasepricewatcher.herokuapp.com/price/BTC")!
            break
        case ETH:
            requestURL = URL(string: "https://coinbasepricewatcher.herokuapp.com/price/ETH")!
            break
        default:
            requestURL = URL(string: "https://coinbasepricewatcher.herokuapp.com/price/BTC")!
        }

        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: requestURL)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            if let err = error {
                print(err)
                return
            }

            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode

            if (statusCode == 200) {
                if let dataObj = data {
                    do {
                        let parsedData = try JSONSerialization.jsonObject(with: dataObj, options: .allowFragments)
                        if let dataDict = parsedData as? Dictionary<String, Any> {
                            self.parseJSON(dataDict)
                        }
                    } catch let throwError as NSError {
                        print(throwError)
                    }
                }
            }
        }
        
        task.resume()
    }

    private func parseJSON(_ dictionary : Dictionary<String, Any>) {
        guard let dataDict = dictionary["data"] as? Dictionary<String, Any> else {
            return
        }
        guard let rates = dataDict["rates"] as? Dictionary<String, Any> else {
            return
        }
        guard let usdPrice = rates["USD"] as? String else {
            return
        }

        DispatchQueue.main.async(){
            self.updatePriceText(usdPrice)
        }
    }

    private func updatePriceText(_ price:String) {
        let result = "$" + price
        self.priceLbl.text = result
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent: Int) -> Int {
        return 2
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent: Int) -> String? {
        switch row {
        case BTC:
            return "BTC"
        case ETH:
            return "ETH"
        default:
            return "BTC"
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        DispatchQueue.global(qos: .background).async {
            self.refreshData(forCurrency: row)
        }

        let defaults = UserDefaults.standard
        defaults.set(row, forKey:currencyKey)
    }
}


//  The MIT License (MIT)
//
//  Copyright (c) 2015 Sándor Gyulai
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import StoreKit

extension Notification.Name {
    
    static let iapPurchased = Notification.Name("IAPPurchasedNotification")
    static let iapFailed = Notification.Name("IAPFailedNotification")
    
}

open class InAppFw: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver{
    
    public static let sharedInstance = InAppFw()
    
    var productIdentifiers: Set<String>?
    var productsRequest: SKProductsRequest?
    
    var completionHandler: ((_ success: Bool, _ products: [SKProduct]?) -> Void)?
    
    var purchasedProductIdentifiers = Set<String>()
    
    fileprivate var hasValidReceipt = false
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        productIdentifiers = Set<String>()
    }
    
    /**
        Add a single product ID
    
        - Parameter id: Product ID in string format
    */
    open func addProduct(_ id: String) {
        productIdentifiers?.insert(id)
    }
    
    /**
        Add multiple product IDs
    
        - Parameter ids: Set of product ID strings you wish to add
    */
    open func addProduct(_ ids: Set<String>) {
        productIdentifiers?.formUnion(ids)
    }
    
    /**
        Load purchased products
    
        - Parameter checkWithApple: True if you want to validate the purchase receipt with Apple servers
    */
    open func loadPurchasedProducts(validate: Bool, completion: ((_ valid: Bool) -> Void)?) {
        
        if let productIdentifiers = productIdentifiers {
            
            for productIdentifier in productIdentifiers {
                
                let isPurchased = UserDefaults.standard.bool(forKey: productIdentifier)
                
                if isPurchased {
                    purchasedProductIdentifiers.insert(productIdentifier)
                    print("Purchased: \(productIdentifier)")
                } else {
                    print("Not purchased: \(productIdentifier)")
                }
                
            }
            
            if validate {
                print("Checking with Apple...")
                if let completion = completion {
                    validateReceipt(false, completion: completion)
                } else {
                    validateReceipt(false) { (valid) -> Void in
                        if valid { print("Receipt is Valid!") } else { print("BEWARE! Reciept is not Valid!!!") }
                    }
                }
            }
            
        }
        
    }
    
    fileprivate func validateReceipt(_ sandbox: Bool, completion: @escaping (_ valid: Bool) -> Void) {
        
        let url = Bundle.main.appStoreReceiptURL
        let receipt = try? Data(contentsOf: url!)
        
        if let r = receipt {
            
            let receiptData = r.base64EncodedString(options: NSData.Base64EncodingOptions())
            let requestContent = [ "receipt-data" : receiptData ]
            
            do {
                let requestData = try JSONSerialization.data(withJSONObject: requestContent, options: JSONSerialization.WritingOptions())
                
                let storeURL = URL(string: "https://buy.itunes.apple.com/verifyReceipt")
                let sandBoxStoreURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")
                
                guard let finalURL = sandbox ? sandBoxStoreURL : storeURL else {
                    return
                }
                
                var storeRequest = URLRequest(url: finalURL)
                storeRequest.httpMethod = "POST"
                storeRequest.httpBody = requestData
                
                let task = URLSession.shared.dataTask(with: storeRequest, completionHandler: { [weak self] (data, response, error) -> Void in
                    if (error != nil) {
                        print("Validation Error: \(String(describing: error))")
                        self?.hasValidReceipt = false
                        completion(false)
                    } else {
                        self?.checkStatus(with: data, completion: completion)
                    }
                })
                
                task.resume()
                
            } catch {
                print("validateReceipt: Caught error serializing response JSON")
            }
            
        } else {
            hasValidReceipt = false
            completion(false)
        }
        
    }
    
    fileprivate func checkStatus(with data: Data?, completion: @escaping (_ valid: Bool) -> Void) {
        do {
            if let data = data, let jsonResponse = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions()) as? [String: AnyObject] {
                
                if let status = jsonResponse["status"] as? Int {
                    if status == 0 {
                        print("Status: VALID")
                        hasValidReceipt = true
                        completion(true)
                    } else if status == 21007 {
                        print("Status: CHECK WITH SANDBOX")
                        validateReceipt(true, completion: completion)
                    } else {
                        print("Status: INVALID")
                        hasValidReceipt = false
                        completion(false)
                    }
                }
                
            }
        } catch {
            print("checkStatus: Caught error")
        }
    }
    
    /**
        Request products from Apple
    */
    open func requestProducts(_ completionHandler: @escaping (_ success:Bool, _ products:[SKProduct]?) -> Void) {
        self.completionHandler = completionHandler
        
        print("Requesting Products")
        
        if let productIdentifiers = productIdentifiers {
            productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productsRequest!.delegate = self
            productsRequest!.start()
        } else {
            print("No productIdentifiers")
            completionHandler(false, nil)
        }
    }
    
    /**
        Initiate purchase for the product
    
        - Parameter product: The product you want to purchase
    */
    open func purchase(_ product: SKProduct) {
        print("Purchasing product: \(product.productIdentifier)")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    /**
        Check if the product with identifier is already purchased
    */
    open func checkPurchase(for productIdentifier: String) -> (isPurchased: Bool, hasValidReceipt: Bool) {
        let purchased = purchasedProductIdentifiers.contains(productIdentifier)
        return (purchased, hasValidReceipt)
    }
    
    /**
        Begin to start restoration of already purchased products
    */
    open func restoreCompletedTransactions() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    //MARK: - Transactions
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        print("Complete Transaction...")
        
        provideContentForProductIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func restoreTransaction(_ transaction: SKPaymentTransaction) {
        print("Restore Transaction...")
        
        provideContentForProductIdentifier(transaction.original!.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        print("Failed Transaction...")
        SKPaymentQueue.default().finishTransaction(transaction)
        NotificationCenter.default.post(name: .iapPurchased, object: nil, userInfo: nil)
    }
    
    fileprivate func provideContentForProductIdentifier(_ productIdentifier: String!) {
        purchasedProductIdentifiers.insert(productIdentifier)
        
        UserDefaults.standard.set(true, forKey: productIdentifier)
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(name: .iapFailed, object: productIdentifier, userInfo: nil)
    }
    
    // MARK: - Delegate Implementations
    
    open func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions
        {
            if let trans = transaction as? SKPaymentTransaction
            {
                switch trans.transactionState {
                case .purchased:
                    completeTransaction(trans)
                    break
                case .failed:
                    failedTransaction(trans)
                    break
                case .restored:
                    restoreTransaction(trans)
                    break
                default:
                    break
                }
            }
        }
    }
    
    open func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {

        print("Loaded product list!")
        
        productsRequest = nil
        
        let skProducts = response.products
        
        for skProduct in skProducts  {
            print("Found product: \(skProduct.productIdentifier) - \(skProduct.localizedTitle) - \(skProduct.price)")
        }
        
        if let completionHandler = completionHandler {
            completionHandler(true, skProducts)
        }
        
        completionHandler = nil

    }
    
    open func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products!")
        productsRequest = nil
        if let completionHandler = completionHandler {
            completionHandler(false, nil)
        }
        completionHandler = nil
    }
    
    //MARK: - Helpers
    
    /**
        Check if the user can make purchase
    */
    open func canMakePurchase() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    //MARK: - Class Functions
    
    /**
        Format the price for the given locale
    
        - Parameter price:  The price you want to format
        - Parameter locale: The price locale you want to format with
    
        - Returns: The formatted price
    */
    open class func formatPrice(_ price: NSNumber, locale: Locale) -> String {
        var formattedString = ""
        
        let numberFormatter = NumberFormatter()
        numberFormatter.formatterBehavior = NumberFormatter.Behavior.behavior10_4
        numberFormatter.numberStyle = NumberFormatter.Style.currency
        numberFormatter.locale = locale
        formattedString = numberFormatter.string(from: price)!
        
        return formattedString
    }
    
}

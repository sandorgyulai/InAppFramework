//
//  InAppFw.swift
//  InAppFw
//
//  Created by Sándor Gyulai on 12/10/15.
//  Copyright © 2015 Sándor Gyulai. All rights reserved.
//

import UIKit
import StoreKit

public class InAppFw: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver{
    
    public let ProductPurchasedNotification = "IAPPurchasedNotification"
    
    static let sharedInstance = InAppFw()
    
    var productIdentifiers: Set<String>?
    var productsRequest: SKProductsRequest?
    
    var completionHandler: ((success: Bool, products: [AnyObject]?) -> Void)?
    
    var purchasedProductIdentifiers = Set<String>()
    
    var hasValidReceipt = false
    
    public override init() {
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        //loadPurchasedProducts(true)
    }
    
    public func addProductId(id: String) {
        productIdentifiers?.insert(id)
    }
    
    public func addProductIds(ids: Set<String>) {
        productIdentifiers?.unionInPlace(ids)
    }
    
    public func loadPurchasedProducts(checkWithApple: Bool, completion: ((valid: Bool) -> Void)?) {
        
        if let productIdentifiers = productIdentifiers {
            for productIdentifier in productIdentifiers {
                
                let isPurchased = NSUserDefaults.standardUserDefaults().boolForKey(productIdentifier)
                
                if isPurchased {
                    print("Purchased: \(productIdentifier)")
                } else {
                    print("Not purchased: \(productIdentifier)")
                }
                
            }
            
            if checkWithApple {
                if let completion = completion {
                    validateReceipt(false, completion: completion)
                } else {
                    validateReceipt(false, completion: { (valid) -> Void in
                        if valid {
                            print("Receipt is Valid!")
                        } else {
                            print("BEWARE! Reciept is not Valid!!!")
                        }
                    })
                }
            }
        }
        
    }
    
    private func validateReceipt(sandbox: Bool, completion:(valid: Bool) -> Void) {
        
        let url = NSBundle.mainBundle().appStoreReceiptURL
        let receipt = NSData(contentsOfURL: url!)
        
        if let r = receipt {
            
            let receiptData = r.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
            let requestContent = ["receipt-data":receiptData]
            
            do {
                let requestData = try NSJSONSerialization.dataWithJSONObject(requestContent, options: NSJSONWritingOptions())
                
                let storeURL = NSURL(string: "https://buy.itunes.apple.com/verifyReceipt")
                let sandBoxStoreURL = NSURL(string: "https://sandbox.itunes.apple.com/verifyReceipt")
                
                let finalURL = sandbox ? sandBoxStoreURL : storeURL
                
                let storeRequest = NSMutableURLRequest(URL: finalURL!)
                storeRequest.HTTPMethod = "POST"
                storeRequest.HTTPBody = requestData
                
                let queue = NSOperationQueue()
 
                NSURLConnection.sendAsynchronousRequest(storeRequest, queue: queue, completionHandler: { (response, data, error) -> Void in
                    if (error != nil) {
                        print("Validation Request Error: \(error)")
                        completion(valid: false)
                    } else {
                        self.checkStatus(data, completion: completion)
                    }
                })
                
            } catch {
                print("validateReceipt: Caught error")
            }
            
        } else {
            hasValidReceipt = false
            completion(valid: false)
        }
        
    }
    
    private func checkStatus(data: NSData?, completion:(valid: Bool) -> Void) {
        do {
            if let data = data, let jsonResponse: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) {
                
                if let status = jsonResponse["status"] as? Int {
                    //print("Validation Status: \(status)")
                    if status == 0 {
                        print("Status: VALID")
                        self.hasValidReceipt = true
                        completion(valid: true)
                    } else if status == 21007 {
                        print("Status: CHECK WITH SANDBOX")
                        self.validateReceipt(true, completion: completion)
                    } else {
                        print("Status: INVALID")
                        self.hasValidReceipt = false
                        completion(valid: false)
                    }
                }
                
            }
        } catch {
            print("checkStatus: Caught error")
        }
    }
    
    public func requestProducts(completionHandler: (success:Bool, products:[AnyObject]?) -> Void) {
        self.completionHandler = completionHandler
        
        if let productIdentifiers = productIdentifiers {
            productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            productsRequest!.delegate = self
            productsRequest!.start()
        } else {
            completionHandler(success: false, products: nil)
        }
        
    }
    
    public func purchaseProduct(product: SKProduct) {
        print("Purchasing product: \(product.productIdentifier)")
        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    public func productPurchased(productIdentifier: String) -> Bool {
        return purchasedProductIdentifiers.contains(productIdentifier)
    }
    
    public func restoreCompletedTransactions() {
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    //MARK: - Product Completions
    
    private func completeTransaction(transaction: SKPaymentTransaction) {
        print("Complete Transaction...")
        
        self.provideContentForProductIdentifier(transaction.payment.productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func restoreTransaction(transaction: SKPaymentTransaction) {
        print("Restore Transaction...")
        
        self.provideContentForProductIdentifier(transaction.originalTransaction!.payment.productIdentifier)
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        print("Failed Transaction...")
        
        if (transaction.error!.code != SKErrorPaymentCancelled)
        {
            print("Transaction error \(transaction.error!.code): \(transaction.error!.localizedDescription)")
        }
        
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }

    private func provideContentForProductIdentifier(productIdentifier: String!) {
    
        purchasedProductIdentifiers.insert(productIdentifier)
        
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: productIdentifier)
        NSUserDefaults.standardUserDefaults().synchronize()
        
        NSNotificationCenter.defaultCenter().postNotificationName(ProductPurchasedNotification, object: productIdentifier, userInfo: nil)
        
    }
    
    // MARK: - Delegate Implementations
    
    public func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions
        {
            if let trans = transaction as? SKPaymentTransaction
            {
                switch trans.transactionState
                {
                case .Purchased:
                    completeTransaction(trans)
                    break
                case .Failed:
                    failedTransaction(trans)
                    break
                case .Restored:
                    restoreTransaction(trans)
                    break
                default:
                    break
                }
            }
        }
    }
    
    public func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {

        print("Loaded product list!")
        
        productsRequest = nil
        
        let skProducts = response.products
        
        for skProduct in skProducts  {
            print("Found product: \(skProduct.productIdentifier) - \(skProduct.localizedTitle) - \(skProduct.price)")
        }
        
        if let completionHandler = completionHandler {
            completionHandler(success: true, products: skProducts)
        }
        
        completionHandler = nil

    }
    
    public func request(request: SKRequest, didFailWithError error: NSError) {
        print("Failed to load list of products!")
        productsRequest = nil
        if let completionHandler = completionHandler {
            completionHandler(success: false, products: nil)
        }
        completionHandler = nil
    }
    
}
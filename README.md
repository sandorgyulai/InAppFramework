# InAppFramework
In App Purchase Manager framework for iOS

##### ToDo for 1.0

- ☐ Documentation!! Work in progress
- ☐ Change productPurchased(productIdentifier: String) -> Bool to return Tuple with 2 bools to replace hasValidReceipt property
- ☑︎ Change NSURLConnection to NSURLSession

### Installation

#### CocoaPods

```
pod 'InAppFw'
```

### Usage

First you should add product IDs:
```swift
InAppFw.sharedInstance.addProductId(String)
InAppFw.sharedInstance.addProductIds([String])
```

Then you can request them from the Apple servers:
```swift
InAppFw.sharedInstance.requestProducts(completionHandler: (success: Bool, products: [SKProduct]?)
```

Make purchases:
```swift
InAppFw.sharedInstance.purchaseProduct(SKProduct)
```

Restore purchases:
```swift
InAppFw.sharedInstance.restoreCompletedTransactions()
```

Register for notifications:
```swift
- kIAPPurchasedNotification
- kIAPFailedNotification
```

Load the previously purchased products:
```swift
InAppFw.sharedInstance.loadPurchasedProducts(checkWithApple: Bool, completion: ((valid: Bool) -> Void)?)
```
```checkWithApple```: if ```true```, will validate the Purchase receipt with Apple Servers too. The completion will be only true if the receipt is valid.
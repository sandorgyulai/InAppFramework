# InAppFramework
In App Purchase Manager framework for iOS

### Disclaimer
I know it's been too long since the last update, quite a few things happened in my life, but now I am back again and started with a nice update for Swift 4.2 compatibility. More to come, stay tuned!

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

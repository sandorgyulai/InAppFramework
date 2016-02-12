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

* Register for Notifications with the name below where you want to do something

```
ProductPurchasedNotificationName
```

* Add your product identifiers

```
InAppFw.sharedInstance.addProductId(id: String)
```

or add multiple of them

```
InAppFw.sharedInstance.addProductIds(ids: Set<String>)
```

* Request products from Apple

```
InAppFw.sharedInstance.requestProducts(completionHandler: (success:Bool, products:[SKProduct]?)
```

* Load the previously purchased products

```
InAppFw.sharedInstance.loadPurchasedProducts(checkWithApple: Bool, completion: ((valid: Bool) -> Void)?)
```

"checkWithApple" if true will validate the Purchase receipt with Apple Servers too. The completion will be only true if the receipt was valid

* Purchase product

```
InAppFw.sharedInstance.purchaseProduct(product: SKProduct)
```

* Or Restore products purchased on an other device

```
InAppFw.sharedInstance.restoreCompletedTransactions()
```

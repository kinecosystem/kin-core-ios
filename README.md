![Kin iOS](.github/kin_ios.png)

#  Kin iOS SDK

A library responsible for creating a new Kin account and managing balance and transactions in Kin.

## Disclaimer

The SDK is not yet ready for third-party use by digital services in the Kin ecosystem.
It is still tested internally by Kik as part of [initial product launch, version 2](https://medium.com/kinfoundation/context-around-iplv2-4b4ec3734417).

## Installation

In the meantime, we don't support yet CocoaPods or Carthage. The recommended setup is adding the KinSDK project as a subproject, and having the SDK as a target dependencies. Here is a step by step that we recommend:

1. Clone this repo (as a submodule or in a different directory, it's up to you);
2. Drag `KinSDK.xcodeproj` as a subproject;
3. In your main `.xcodeproj` file, select the desired target(s);
4. Go to **Build Phases**, expand Target Dependencies, and add `KinSDK`;
5. In Swift, `import KinSDK` and you are good to go! (We haven't yet tested Obj-C)

This is how we did the Sample App - you might look at the setup for a concrete example.

## API Usage

### `KinClient`
`KinClient` is where you start from. In order to initialize it, you'll need a Horizon end-point on the network of your choice.

```swift
let kinClient = try? KinClient(with: URL, networkId: NetworkId)
```

No activity can take place until an account is created and activated (see below). To do so, call `createAccountIfNeeded(with passphrase: String)`. To check if an account already exists, you can inspect the `account` property. The passphrase used to encrypt the account is the same one used to get the key store and send transactions.

### `KinAccount`

#### Activation

Before an account can receive KIN, it must be activated.

```swift
account.activate(passphrase: "pass phrase", completion: { txHash, error in
    if error == nil {
        // report success
    }
})
```

#### Public Address and Private Key

- `var publicAddress: String`: returns a text representation of the account's public key.

**Note** For the methods below, a sync and an async version are both available. The sync versions will block the current thread until a value is returned (so you should call them from the main thread). The async versions will call the completion block once finished, but **it is the developer's responsibility to dispatch to desired queue.**

#### Checking Balance

- `func balance() throws -> Balance`: returns the current balance of the account.

#### Sending transactions

- `func sendTransaction(to: String, kin: Double, passphrase: String) throws -> TransactionId`: Sends a specific amount to an account's address, given the passphrase. Throws an error in case the passphrase is wrong. Returns the transaction ID. **Currently returns a hardcoded value of `MockTransactionId`**

## Error handling

`KinSDK` wraps errors in an operation-specific error for each method of `KinAccount`.  The underlying error is the actual cause of failure.

### Common errors

`StellarError.missingAccount`: The account does not exist on the Stellar network.  You must create the account by issuing a `CREATE_ACCOUNT` operation with `KinAccount.publicAddress` as the destination.  This is done using an app-specific service, and is outside the scope of this SDK.

`StellarError.missingBalance`: For an account to receive KIN, it must trust the KIN Issuer.  Call `KinAccount.activate()` to perform this operation.

## Contributing

Please review our [CONTRIBUTING.md](CONTRIBUTING.md) guide before opening issues and pull requests.

## License
This repository is licensed under the [MIT license](LICENSE.md).

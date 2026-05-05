# `@super-app/sdk`

The official JavaScript SDK for building Mini Apps on the Super App platform. This SDK provides a clean, promise-based interface to access native device features and core Super App services.

## Installation

Install the SDK in your Mini App project using npm or yarn:

```bash
npm install @super-app/sdk
# or
yarn add @super-app/sdk
```

## Usage

Import the `superApp` singleton instance into your JavaScript/TypeScript files:

```javascript
import superApp from '@super-app/sdk';

// Example: Get user info
async function getUserData() {
  try {
    const user = await superApp.user.getInfo();
    console.log('User Info:', user);
  } catch (error) {
    console.error('Failed to get user info:', error.message);
  }
}

// Example: Listen for unsolicited messages from the Super App host
superApp.on('message', (msg) => {
  console.log('Message from Super App:', msg);
});

// Don't forget to clean up listeners if your component unmounts
// superApp.off('message', myHandler);
```

## Available APIs

All API calls return a `Promise` which resolves with the result or rejects with an `Error` object if the operation fails (e.g., permission denied, host error).

### `superApp.user`

Provides access to user-related information.

#### `superApp.user.getInfo(): Promise<{name: string, id: string, email: string}>`

Retrieves the current user's profile information.

**Permissions Required:** `user.getUserInfo`

### `superApp.device`

Provides access to device-specific features.

#### `superApp.device.getBatteryLevel(): Promise<number>`

Retrieves the current battery level of the device (0-100).

**Permissions Required:** `device.getBatteryLevel`

### `superApp.auth`

Provides authentication services.

#### `superApp.auth.login(): Promise<{token: string}>`

Initiates a login process with the Super App. This typically opens a native login screen.

**Permissions Required:** `auth.login`

#### `superApp.auth.logout(): Promise<boolean>`

Logs out the user from the Super App.

**Permissions Required:** `auth.logout`

#### `superApp.auth.getToken(): Promise<string>`

Retrieves the current authentication token. Returns a rejected promise if the user is not logged in.

**Permissions Required:** `auth.getToken`

### `superApp.payment`

Provides payment processing capabilities.

#### `superApp.payment.initiate(amount: number, currency: string): Promise<{transactionId: string, status: string, amount: number, currency: string}>`

Initiates a payment process. The Super App will handle the payment flow.

**Parameters:**
- `amount`: The amount to be paid (e.g., `50.00`).
- `currency`: The 3-letter currency code (e.g., `'USD'`, `'EUR'`).

**Permissions Required:** `payment.initiatePayment`

### Event Listener (`superApp.on`, `superApp.off`)

The SDK provides an event emitter for unsolicited messages pushed from the Super App host.

#### `superApp.on(eventName: 'message', callback: (message: string) => void): void`

Subscribes to messages sent from the Super App host (e.g., notifications, system events).

#### `superApp.off(eventName: 'message', callback: (message: string) => void): void`

Unsubscribes a previously registered callback.

## Security Model: Permissions

Mini Apps operate within a strict security sandbox. To access any native device feature or Super App service, the Mini App **must explicitly declare the required permissions** in its `public/manifest.json` file.

Example `public/manifest.json`:

```json
{
  "name": "My Awesome Mini App",
  "version": "1.0.0",
  "permissions": [
    "user.getUserInfo",
    "device.getBatteryLevel",
    "payment.initiatePayment"
  ]
}
```

If a Mini App attempts to call an API for which it does not have declared permission, the SDK call will result in a rejected promise with a 'Permission denied' error.

## Error Handling

All SDK API calls return Promises. It is crucial to handle potential rejections using `.catch()` or `try...catch` with `async/await`.

```javascript
try {
  const result = await superApp.someApiCall();
  // Handle success
} catch (error) {
  console.error('API call failed:', error.message);
  // Display error to user
}
```
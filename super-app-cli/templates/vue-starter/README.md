# Vue Starter Mini App

This is a starter template for building Mini Apps using Vue.js on the Super App platform.

## Available Scripts

In the project directory, you can run:

### `npm run serve`

Runs the app in development mode. Open your Super App and launch this Mini App (via remote URL pointing to `http://localhost:8080`) to test.

### `npm run build`

Builds the app for production to the `dist` folder. This optimized build is ready to be packaged into a `.zip` file and uploaded to the Super App backend for dynamic loading.

### `super-app-cli serve`

Starts the development server.

### `super-app-cli build`

Builds the app for production and creates a `.zip` archive ready for deployment.

## Super App SDK Integration

This Mini App comes pre-configured with the `@super-app/sdk`. You can import it like this:

```javascript
import superApp from '@super-app/sdk';
```

For detailed documentation on available APIs, permissions, and usage, please refer to the Super App SDK Documentation (replace with actual link).

## Permissions

Remember to declare all required permissions in your `public/manifest.json` file.

```json
{
  "name": "My Vue Mini App",
  "version": "1.0.0",
  "permissions": [
    "user.getUserInfo",
    "device.getBatteryLevel"
  ]
}
```
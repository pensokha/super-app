// A simple event emitter for unsolicited messages from the host
class EventEmitter {
  constructor() {
    this.listeners = {};
  }

  on(eventName, callback) {
    if (!this.listeners[eventName]) {
      this.listeners[eventName] = [];
    }
    this.listeners[eventName].push(callback);
  }

  off(eventName, callback) {
    if (this.listeners[eventName]) {
      this.listeners[eventName] = this.listeners[eventName].filter(
        (cb) => cb !== callback
      );
    }
  }

  emit(eventName, data) {
    if (this.listeners[eventName]) {
      this.listeners[eventName].forEach((callback) => callback(data));
    }
  }
}

class SuperAppSDK {
  constructor() {
    this.requestId = 1;
    this.pendingRequests = new Map();
    this.emitter = new EventEmitter();
    this._initializeListeners();

    // --- Define the public API ---
    this.user = {
      /**
       * Retrieves user information from the Super App.
       * @returns {Promise<{name: string, id: string, email: string}>} A promise that resolves with the user object.
       */
      getInfo: () => this._request('user.getUserInfo'),
    };

    this.device = {
      /**
       * Retrieves the current battery level of the device.
       * @returns {Promise<number>} A promise that resolves with the battery level (0-100).
       */
      getBatteryLevel: () => this._request('device.getBatteryLevel'),
    };
  }

  /**
   * Private method to send a request to the Flutter host and return a Promise.
   * @private
   */
  _request(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = this.requestId++;
      this.pendingRequests.set(id, { resolve, reject });

      const message = {
        jsonrpc: '2.0',
        method,
        params,
        id,
      };

      if (window.SuperAppBridge) {
        window.SuperAppBridge.postMessage(JSON.stringify(message));
      } else {
        console.error('SuperAppBridge not found. Are you running inside the Super App?');
        reject(new Error('SuperAppBridge not found.'));
      }
    });
  }

  /**
   * Private method to set up global listeners for messages from the host.
   * @private
   */
  _initializeListeners() {
    // Listener for responses to our requests
    document.addEventListener('superAppResponse', (event) => {
      try {
        const jsonString = atob(event.detail);
        const data = JSON.parse(jsonString);

        if (data.id && this.pendingRequests.has(data.id)) {
          const { resolve, reject } = this.pendingRequests.get(data.id);
          if (data.result) {
            resolve(data.result);
          } else if (data.error) {
            reject(new Error(data.error.message || 'Unknown error from host'));
          }
          this.pendingRequests.delete(data.id);
        }
      } catch (e) {
        console.error('SDK failed to process response from host:', e);
      }
    });

    // Listener for unsolicited messages pushed from the host
    document.addEventListener('flutterMessage', (event) => {
      try {
        const message = atob(event.detail);
        this.emitter.emit('message', message);
      } catch (e) {
        console.error('SDK failed to process pushed message from host:', e);
      }
    });
  }

  on = (eventName, callback) => this.emitter.on(eventName, callback);
  off = (eventName, callback) => this.emitter.off(eventName, callback);
}

// Export a singleton instance of the SDK for the entire Mini App to use.
const superApp = new SuperAppSDK();
export default superApp;
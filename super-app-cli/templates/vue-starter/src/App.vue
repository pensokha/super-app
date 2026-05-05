<template>
  <div id="app">
    <header class="app-header">
      <h1>Vue ↔️ Flutter Bridge</h1>
      <p>Using the new <code>@super-app/sdk</code></p>

      <h2>User & Device APIs</h2>
      <button @click="requestUserInfo">Get User Info via SDK</button>
      <div v-if="userInfo" class="info-box">
        <h3>User Info Received:</h3>
        <pre>{{ JSON.stringify(userInfo, null, 2) }}</pre>
      </div>
      <button @click="requestBatteryLevel" style="margin-top: 20px;">Get Battery Level via SDK</button>
      <p v-if="batteryLevel" style="margin-top: 10px;">Battery Level: {{ batteryLevel }}</p>

      <h2>Auth Service</h2>
      <p>Status: {{ authStatus }}</p>
      <button @click="login">Login</button>
      <button @click="logout" style="margin-left: 10px;">Logout</button>
      <button @click="getToken" style="margin-left: 10px;">Get Token</button>
      <p v-if="authToken" style="margin-top: 10px;">Token: {{ authToken }}</p>

      <h2>Payment Service</h2>
      <button @click="initiatePayment(50.00, 'USD')">Pay 50 USD</button>
      <button @click="initiatePayment(13.37, 'EUR')" style="margin-left: 10px;">Pay 13.37 EUR (Fails)</button>
      <button @click="initiatePayment(1500.00, 'USD')" style="margin-left: 10px;">Pay 1500 USD (Fails)</button>
      <div v-if="paymentResult" class="info-box" style="margin-top: 20px;">
        <h3>Payment Result:</h3>
        <pre>{{ JSON.stringify(paymentResult, null, 2) }}</pre>
      </div>

      <p v-if="messageFromFlutter" style="margin-top: 20px; color: #61dafb;">Message from Flutter: {{ messageFromFlutter }}</p>
    </header>
  </div>
</template>

<script>
import superApp from '@super-app/sdk';

export default {
  name: 'App',
  data() {
    return {
      userInfo: null,
      messageFromFlutter: '',
      batteryLevel: null,
      authStatus: 'Logged Out',
      authToken: null,
      paymentResult: null,
      JSON: JSON, // Make JSON available in template
    };
  },
  mounted() {
    superApp.on('message', this.handlePushedMessage);
  },
  beforeUnmount() {
    superApp.off('message', this.handlePushedMessage);
  },
  methods: {
    handlePushedMessage(message) {
      console.log('Received pushed message via SDK:', message);
      this.messageFromFlutter = message;
    },
    async requestUserInfo() {
      try {
        this.userInfo = null;
        const user = await superApp.user.getInfo();
        this.userInfo = user;
      } catch (error) {
        console.error('Failed to get user info via SDK:', error);
        this.userInfo = { name: `Error: ${error.message}` };
      }
    },
    async requestBatteryLevel() {
      try {
        this.batteryLevel = 'loading...';
        const level = await superApp.device.getBatteryLevel();
        this.batteryLevel = `${level}%`;
      } catch (error) {
        console.error('Failed to get battery level via SDK:', error);
        this.batteryLevel = `Error: ${error.message}`;
      }
    },
    async login() { /* ... (similar to React App.js) ... */ },
    async logout() { /* ... (similar to React App.js) ... */ },
    async getToken() { /* ... (similar to React App.js) ... */ },
    async initiatePayment(amount, currency) {
      try {
        this.paymentResult = 'Initiating payment...';
        const result = await superApp.payment.initiate(amount, currency);
        this.paymentResult = result;
      } catch (error) {
        console.error('Payment failed:', error);
        this.paymentResult = `Payment Error: ${error.message}`;
      }
    },
  },
};
</script>

<style>
.app-header {
  background-color: #282c34;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: calc(10px + 2vmin);
  color: white;
}
.info-box {
  margin-top: 20px;
  border: 1px solid #42b983; /* Vue green */
  padding: 10px;
  width: 80%;
}
pre {
  text-align: left;
  font-size: 0.8em;
}
button {
  background-color: #42b983; /* Vue green */
}
button:hover {
  background-color: #369b6d;
}
</style>
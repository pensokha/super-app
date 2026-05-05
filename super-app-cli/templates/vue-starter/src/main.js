import { createApp } from 'vue';
import App from './App.vue';

// --- Bridge Logic (copied from React index.js) ---
window.handleSuperAppResponseFromBase64 = (base64Response) => {
  document.dispatchEvent(new CustomEvent('superAppResponse', { detail: base64Response }));
};
window.showFlutterMessageFromBase64 = (base64Message) => {
  document.dispatchEvent(new CustomEvent('flutterMessage', { detail: base64Message }));
};

createApp(App).mount('#app');
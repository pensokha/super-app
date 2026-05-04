import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';

// --- Bridge Logic ---
// Define the global functions that Flutter will call.
// This ensures they exist immediately, avoiding any race conditions with the React lifecycle.

/**
 * Handles responses from the Super App for requests initiated by the Mini App.
 * @param {string} base64Response - A Base64 encoded JSON string.
 */
window.handleSuperAppResponseFromBase64 = (base64Response) => {
  const event = new CustomEvent('superAppResponse', { detail: base64Response });
  document.dispatchEvent(event);
};

/**
 * Handles unsolicited messages pushed from the Super App.
 * @param {string} base64Message - A Base64 encoded string.
 */
window.showFlutterMessageFromBase64 = (base64Message) => {
  const event = new CustomEvent('flutterMessage', { detail: base64Message });
  document.dispatchEvent(event);
};

// --- React App Rendering ---

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();

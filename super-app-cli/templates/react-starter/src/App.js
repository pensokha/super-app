import { useState, useEffect } from 'react';
import './App.css';
import superApp from '@super-app/sdk'; // Import from the installed package

function App() {
  const [userInfo, setUserInfo] = useState(null);
  const [messageFromFlutter, setMessageFromFlutter] = useState('');
  const [batteryLevel, setBatteryLevel] = useState(null);

  useEffect(() => {
    // The SDK now handles all the complex event listening for us.
    // We just need to subscribe to the events we care about.
    const handlePushedMessage = (message) => {
      console.log('Received pushed message via SDK:', message);
      setMessageFromFlutter(message);
    };

    // Subscribe to unsolicited 'message' events from the host
    superApp.on('message', handlePushedMessage);

    // Cleanup: remove event listeners when the component unmounts
    return () => {
      superApp.off('message', handlePushedMessage);
    };
  }, []); // Empty dependency array ensures this runs only once

  // The request function is now async and much cleaner.
  const requestUserInfo = async () => {
    try {
      setUserInfo(null); // Clear previous user info
      const user = await superApp.user.getInfo();
      setUserInfo(user);
    } catch (error) {
      console.error('Failed to get user info via SDK:', error);
      // Display the error in the UI
      setUserInfo({ name: `Error: ${error.message}` });
    }
  };

  const requestBatteryLevel = async () => {
    try {
      setBatteryLevel('loading...');
      const level = await superApp.device.getBatteryLevel();
      setBatteryLevel(`${level}%`);
    } catch (error) {
      console.error('Failed to get battery level via SDK:', error);
      setBatteryLevel(`Error: ${error.message}`);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>JS ↔️ Flutter Bridge</h1>
        <p>Using the new <code>@super-app/sdk</code></p>
        <button onClick={requestUserInfo}>Get User Info via SDK</button>
        {userInfo && (
          <div style={{marginTop: '20px', border: '1px solid #61dafb', padding: '10px', width: '80%'}}>
            <h3>User Info Received:</h3>
            <pre style={{textAlign: 'left', fontSize: '0.8em'}}>{JSON.stringify(userInfo, null, 2)}</pre>
          </div>
        )}
        <button style={{marginTop: '20px'}} onClick={requestBatteryLevel}>Get Battery Level via SDK</button>
        {batteryLevel && <p style={{marginTop: '10px'}}>Battery Level: {batteryLevel}</p>}
        {messageFromFlutter && <p style={{marginTop: '20px', color: '#61dafb'}}>Message from Flutter: {messageFromFlutter}</p>}
      </header>
    </div>
  );
}

export default App;

// server.js
const express = require('express');
const path = require('path');
const cors = require('cors');

const app = express();
const port = 3000;

// Enable CORS so your Flutter app can call the API
app.use(cors());

// Serve static files (our mini-app packages) from the 'packages' directory
app.use('/packages', express.static(path.join(__dirname, 'packages')));

// In a real-world application, this data would come from a database.
const miniAppRegistry = [
  {
    type: 'local', // 'local' for zipped package, 'remote' for a URL
    appName: 'hello_world',
    displayName: 'Hello World App (Local)',
    version: '1.1.3',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/733/733581.png', // A local/zip icon
    // The packageUrl is now constructed dynamically to avoid version mismatch errors.
    get packageUrl() { return `http://localhost:${port}/packages/${this.appName}_v${this.version}.zip`; }
  },
  {
    type: 'remote',
    appName: 'react_docs',
    displayName: 'React Docs (Remote)',
    version: '1.0.0',
    iconUrl: 'https://cdn-icons-png.flaticon.com/512/875/875209.png', // A remote/link icon
    remoteUrl: 'https://hello-world-miniapp-pi.vercel.app' // The direct URL to load in the WebView
  }
  // You can add other mini-apps to this array
];

// API endpoint to get metadata for all or a specific mini-app
app.get('/miniapps', (req, res) => {
  const { appName } = req.query;

  // This helper function correctly serializes a mini-app object for the response.
  // It resolves getters and makes URLs dynamic based on the request's host.
  const serializeApp = (app) => {
    const host = req.get('host') || `localhost:${port}`;
    const protocol = req.protocol;

    const serialized = {
      type: app.type,
      appName: app.appName,
      displayName: app.displayName,
      version: app.version,
      iconUrl: app.iconUrl,
    };

    if (app.type === 'local' && app.packageUrl) {
      // Resolve the getter and make the host dynamic
      const packageUrlPath = new URL(app.packageUrl).pathname;
      serialized.packageUrl = `${protocol}://${host}${packageUrlPath}`;
    } else if (app.type === 'remote' && app.remoteUrl) {
      serialized.remoteUrl = app.remoteUrl;
    }

    return serialized;
  };

  if (appName) {
    const app = miniAppRegistry.find(app => app.appName === appName);
    if (app) {
      return res.json(serializeApp(app));
    }
    return res.status(404).json({ error: 'MiniApp not found' });
  }

  // If no appName is specified, return the entire list.
  const allApps = miniAppRegistry.map(serializeApp);
  res.json(allApps);
});

app.listen(port, () => {
  console.log(`Super App backend listening at http://localhost:${port}`);
  console.log('Make sure you have a `packages` directory with your mini-app zip files.');
});

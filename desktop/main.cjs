const { app, BrowserWindow, shell } = require('electron');
const path = require('node:path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 920,
    minWidth: 1024,
    minHeight: 700,
    title: 'HSE MILTI CATERING',
    backgroundColor: '#091324',
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });

  win.loadFile(path.join(__dirname, 'app.html'));
  win.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('https://') || url.startsWith('http://')) shell.openExternal(url);
    return { action: 'deny' };
  });
  win.webContents.on('did-finish-load', () => {
    win.webContents.insertCSS(`
      body { min-width: 1000px !important; }
      .app { max-width: 1440px !important; padding: 0 30px 44px !important; }
      .nav { max-width: 1440px !important; }
      .grid, .cards, .dashboard-grid { grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); }
    `).catch(() => {});
  });
}

app.whenReady().then(() => {
  createWindow();
  app.on('activate', () => { if (BrowserWindow.getAllWindows().length === 0) createWindow(); });
});
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit(); });

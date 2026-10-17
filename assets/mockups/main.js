const { app, BrowserWindow, globalShortcut } = require('electron');
const path = require('path');

function createWindow() {
    const mainWindow = new BrowserWindow({
        width: 1920,
        height: 1080,
        fullscreen: true, // 10-foot OS experience
        frame: false,     // Chromeless
        backgroundColor: '#000000',
        webPreferences: {
            nodeIntegration: true,
            contextIsolation: false
        }
    });

    // Load the 10-foot UI overlay
    mainWindow.loadFile('index.html');

    // Optional: Open DevTools for debugging
    // mainWindow.webContents.openDevTools();

    // Escape to quit (temporary for development)
    globalShortcut.register('Escape', () => {
        app.quit();
    });
}

app.whenReady().then(() => {
    createWindow();

    app.on('activate', function () {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', function () {
    if (process.platform !== 'darwin') app.quit();
});

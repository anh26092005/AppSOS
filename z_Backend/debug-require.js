try {
    const sosController = require('./controllers/sos.controller');
    console.log('✅ Loaded sos.controller successfully');
    console.log('Exports:', Object.keys(sosController));
} catch (error) {
    const fs = require('fs');
    fs.writeFileSync('error.log', error.stack || error.toString());
    console.error('❌ Error logged to error.log');
}

const fs = require('node:fs');

try {
    const data = fs.readFileSync('raw_openapi.json', 'utf8');
    fs.writeFileSync('openapi.json', JSON.stringify(JSON.parse(data), null, 4));
} catch (err) {
    console.error(err);
}

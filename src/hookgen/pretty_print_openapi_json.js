const fs = require('node:fs');

try {
    const data = fs.readFileSync('../openapi.json', 'utf8');
    fs.writeFileSync('pretty_print_openapi.json', JSON.stringify(JSON.parse(data), null, 4));
} catch (err) {
    console.error(err);
}

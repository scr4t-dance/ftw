/* curl -s http://localhost:8080/openapi.json -o openapi.json */
/* npm run orval --config ./orval.config.js */
module.exports = {
    'ftw': {
        input: {
            target: './test.json',
            validation: true,
        },
        output: {
            mode: 'tags-split',
            target: './src/ftw.ts',
            schemas: './src/model',
            client: 'react-query',
            mock: true,
        },
    },
};
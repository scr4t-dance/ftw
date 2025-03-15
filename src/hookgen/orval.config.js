/* curl -s http://localhost:8080/openapi.json -o openapi.json */
/* node test_orval.js */
/* npm run orval --config ./orval.config.js */
module.exports = {
    'ftw': {
        input: {
            target: './test.json',
            validation: false,
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
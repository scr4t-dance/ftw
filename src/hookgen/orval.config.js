/* curl -s http://localhost:8080/openapi.json -o openapi.json */
/* node pretty_print_openapi_json.js */
/* ./node_modules/.bin/orval --config ./orval.config.js */
module.exports = {
    'ftw': {
        input: {
            target: './pretty_print_openapi.json',
            validation: false,
        },
        output: {
            mode: 'tags-split',
            target: '../frontend/src/hookgen/ftw.ts',
            schemas: '../frontend/src/hookgen/model',
            client: 'react-query',
            mock: false,
            baseUrl: 'http://localhost:8080',
            clean: true,
        },
    },
};

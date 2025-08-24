/* curl -s http://localhost:8080/openapi.json -o openapi.json */
/* node pretty_print_openapi_json.js */
/* ./node_modules/.bin/orval --config ./orval.config.js */
module.exports = {
    'ftw': {
        input: {
            target: '../openapi.json',
            validation: false,
        },
        output: {
            mode: 'tags-split',
            target: '../frontend/app/hookgen/ftw.ts',
            schemas: '../frontend/app/hookgen/model',
            client: 'react-query',
            mock: false,
            clean: true,
            shouldSplitQueryKey: true,
            override: {
                mutator: {
                    path: './api/custom_axios_instance.ts',
                    name: 'customInstance',
                },

            },
        },
    },
};

import { defineConfig } from '@hey-api/openapi-ts';

export default defineConfig({
  //input: 'http://localhost:5231/openapi/v1.json',
  input: '../api.json',
  output: {
    format: 'prettier',
    lint: 'eslint',
    path: './src/client',
  },
  
  plugins: [
    {
      name: '@hey-api/client-fetch',
      runtimeConfigPath: './src/configureApiClient.ts', 
    },
    {
      enums: 'javascript',
      name: '@hey-api/typescript',
    },
    {
      name: '@hey-api/sdk'
    },
  ]
});
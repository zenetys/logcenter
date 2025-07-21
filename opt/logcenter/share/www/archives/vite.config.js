import { fileURLToPath, URL } from 'node:url'
import fs from 'node:fs'
import path from 'node:path'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import * as sass from 'sass-embedded'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  css: {
    preprocessorOptions: {
      scss: {
        // Use sass-embedded instead of legacy API
      }
    },
    devSourcemap: true,
    // Specify the Sass implementation to use
    preprocessor: 'sass-embedded'
  },
  base: './',
  server: {
    // Development server configuration
    proxy: {},  // Keep the ability to configure other proxies
    // Custom middleware to serve the API
    middlewareMode: false,
    configureServer(server) {
      server.middlewares.use('/api/list-archives', (req, res) => {
        // Set Content-Type header for JSON
        res.setHeader('Content-Type', 'application/json');
        // Read JSON file and send it back
        const jsonContent = fs.readFileSync(
          path.resolve(__dirname, 'list-archives.json'),
          'utf-8'
        );
        res.end(jsonContent);
      });
    },
  },
})

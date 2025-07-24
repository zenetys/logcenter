import { fileURLToPath, URL } from 'node:url'
import fs from 'node:fs'
import path from 'node:path'
import { execFileSync } from 'node:child_process'
import https from 'node:https'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import * as sass from 'sass-embedded'

// Utility function to prepare CGI environment variables
const prepareCgiEnv = (req) => {
  return {
    ...process.env,
    HTTP_REMOTE_USER: req.headers['remote-user'] || '',
    HTTP_REMOTE_NAME: req.headers['remote-name'] || '',
    HTTP_REMOTE_GROUPS: req.headers['remote-groups'] || '',
    // Variables CGI standard
    SCRIPT_NAME: '/test-local-dev.cgi',
    REQUEST_URI: req.url,
    QUERY_STRING: req.url.split('?')[1] || '',
    REQUEST_METHOD: req.method,
    SERVER_PROTOCOL: 'HTTP/' + (req.httpVersion || '1.1'),
    SERVER_NAME: req.headers.host?.split(':')[0] || 'localhost',
    SERVER_PORT: req.headers.host?.split(':')[1] || '5173',
    CONTENT_TYPE: req.headers['content-type'] || '',
    CONTENT_LENGTH: req.headers['content-length'] || '',
    HTTP_HOST: req.headers.host || '',
    HTTP_USER_AGENT: req.headers['user-agent'] || '',
    HTTP_ACCEPT: req.headers.accept || ''
  };
};

// Utility function to execute CGI script and process its output
const executeCgiScript = (scriptPath, req, res) => {
  // Check if the file exists
  if (!fs.existsSync(scriptPath)) {
    console.error(`Script not found at ${scriptPath}`);
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ status: 'error', message: 'Script not found' }));
    return false;
  }

  try {
    // Execute the script with appropriate environment variables
    const result = execFileSync(scriptPath, [], {
      env: prepareCgiEnv(req)
    }).toString();

    // Parse CGI output - handle both \r\n and \n formats
    const parts = result.split(/\r\n\r\n|\n\n/, 2);
    const headersPart = parts[0] || '';
    const body = parts[1] || '';
    
    // Split headers by both possible line ending formats
    const headers = headersPart.split(/\r\n|\n/).filter(Boolean);

    // Process headers
    headers.forEach(header => {
      if (!header) return;
      
      if (header.startsWith('Status:')) {
        const statusCode = parseInt(header.split(':')[1].trim());
        res.statusCode = statusCode;
      } else {
        const [name, value] = header.split(':').map(part => part.trim());
        res.setHeader(name, value);
      }
    });

    // Send response
    res.end(body);
    return true;
  } catch (error) {
    console.error(`Error executing ${path.basename(scriptPath)}:`, error);
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({
      status: 'error',
      message: `Failed to execute script: ${error.message || 'Unknown error'}`
    }));
    return false;
  }
};

// Définition des routes à traiter

// 1. Routes à rediriger vers le script CGI local
// Format: { path: '/chemin/url', script: 'chemin/vers/script.cgi' }
const cgiRoutes = [
  // Exemple: une route '/api/local-config' qui exécute le script 'test-local-dev.cgi'
  { path: '/api/local-config', script: 'test-local-dev.cgi' },
  // Exemple: une route '/api/stats' qui exécute le script 'stats.cgi'
  { path: '/api/stats', script: 'stats.cgi' },
  { path: '/api/config', script: 'test-local-dev.cgi' },
  { path: '/config.json', script: 'test-local-dev.cgi' },
];

// 2. Routes à rediriger vers le proxy (127.0.0.1:9443)
const proxyRoutes = [
  // '/api/list-archives',
  // '/config.json',
  // '/api/config',
];

// 3. Routes pour servir des fichiers statiques avec un content-type spécifique
const staticFileRoutes = [
  { path: '/api/list-archives', file: 'public/sample.json', contentType: 'application/json' },
  { path: '/config.json', file: 'public/config.json', contentType: 'application/json' },
];

// Plugin pour gérer les routes CGI, proxy et fichiers statiques
const routingPlugin = () => {
  return {
    name: 'routing-plugin',
    configureServer(server) {
      // Middleware pour gérer les routes CGI
      server.middlewares.use((req, res, next) => {
        const url = new URL(req.url, `http://${req.headers.host}`);
        const pathname = url.pathname;
        
        // Vérifier si la route doit être traitée par un script CGI
        const cgiRoute = cgiRoutes.find(route => route.path === pathname);
        
        if (cgiRoute) {
          // Résoudre le chemin du script CGI à partir du nom de fichier dans la configuration
          const cgiScriptPath = path.resolve(__dirname, cgiRoute.script);
          console.log(`Executing CGI script ${cgiRoute.script} for ${pathname} request`);
          executeCgiScript(cgiScriptPath, req, res);
        } else {
          next();
        }
      });
      
      // Middleware pour servir des fichiers statiques
      server.middlewares.use((req, res, next) => {
        const url = new URL(req.url, `http://${req.headers.host}`);
        const pathname = url.pathname;
        
        // Trouver la configuration du fichier statique correspondant
        const staticFile = staticFileRoutes.find(route => route.path === pathname);
        
        if (staticFile) {
          console.log(`Serving static file for ${pathname}`);
          // Définir le Content-Type
          res.setHeader('Content-Type', staticFile.contentType);
          
          try {
            // Lire et envoyer le fichier
            const fileContent = fs.readFileSync(
              path.resolve(__dirname, staticFile.file),
              'utf-8'
            );
            res.end(fileContent);
          } catch (error) {
            console.error(`Error serving static file ${staticFile.file}:`, error);
            res.statusCode = 500;
            res.end(JSON.stringify({ error: 'Failed to read file' }));
          }
        } else {
          next();
        }
      });
      
      // Note: Les routes proxy sont gérées par la configuration server.proxy de Vite
      // Ce middleware est utilisé uniquement pour la journalisation
      server.middlewares.use((req, res, next) => {
        const url = new URL(req.url, `http://${req.headers.host}`);
        const pathname = url.pathname;
        
        // Journaliser les requêtes vers les routes proxy
        if (proxyRoutes.includes(pathname)) {
          console.log(`Route ${pathname} will be handled by proxy configuration`);
        }
        
        // Toujours passer au middleware suivant pour que la configuration proxy de Vite puisse prendre le relais
        next();
      });
    }
  };
};

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    routingPlugin(),
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
    // Configuration du serveur de développement
    proxy: (() => {
      // Générer dynamiquement la configuration du proxy à partir du tableau proxyRoutes
      const proxyConfig = {};
      
      // Configuration commune pour tous les proxys
      const commonProxyConfig = {
        target: 'https://127.0.0.1:9443',
        changeOrigin: true,
        secure: false, // Ne pas vérifier le certificat
        rewrite: (path) => `/archives${path}`,  // Add '/archives' prefix to all proxied requests
        configure: (proxy, _options) => {
          proxy.on('error', (err, _req, _res) => {
            console.log(`Proxy error for ${_req?.url || 'unknown route'}:`, err);
          });
          proxy.on('proxyReq', (proxyReq, req, _res) => {
            console.log(`Proxying ${req.method} ${req.url} to https://127.0.0.1:9443${proxyReq.path}`);
          });
        },
        agent: new https.Agent({
          rejectUnauthorized: false // Ignorer les erreurs de certificat
        })
      };
      
      // Appliquer la configuration à chaque route du tableau proxyRoutes
      proxyRoutes.forEach(route => {
        proxyConfig[route] = { ...commonProxyConfig };
      });
      
      return proxyConfig;
    })(),
    // Configuration du middleware
    middlewareMode: false,
    configureServer(server) {
      // Middleware pour journaliser les requêtes
      server.middlewares.use((req, res, next) => {
        console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
        next();
      });
    },
  },
})

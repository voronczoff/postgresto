#!/bin/sh
set -eu

# Run after the image's configurator; Node is bundled with Swagger UI.
node <<'JS'
const fs = require('node:fs');
const bundle = fs.readFileSync('/usr/share/nginx/html/swagger-ui-bundle.js', 'utf8');
const version = bundle.match(/\bPACKAGE_VERSION\s*:\s*"([^"]+)"/)?.[1] ?? null;
fs.writeFileSync('/usr/share/nginx/html/version.json', JSON.stringify({ version }));
const base = process.env.API_BASE_URL.replace(/\/$/, '');
const schemas = [...new Set(process.env.PGSCHEMAS.split(',').map(s => s.trim()).filter(Boolean))];
const urls = schemas.map(name => ({ name, url: `${base}/${encodeURIComponent(name)}/` }));

fs.writeFileSync('/usr/share/nginx/html/swagger-initializer.js', `
window.onload = function () {
  const urls = ${JSON.stringify(urls)};
  window.ui = SwaggerUIBundle({
    urls,
    "urls.primaryName": ${JSON.stringify(schemas[0])},
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [SwaggerUIBundle.presets.apis, SwaggerUIStandalonePreset],
    plugins: [SwaggerUIBundle.plugins.DownloadUrl],
    layout: 'StandaloneLayout',
    requestInterceptor: function (request) {
      // Spec URLs select a schema through nginx. API calls also need profile
      // headers because PostgREST advertises one shared API base URL.
      const specUrl = request.loadSpec ? request.url : window.ui.specSelectors.url();
      const selected = urls.find(entry =>
        new URL(entry.url, window.location.href).href === new URL(specUrl, window.location.href).href
      );
      if (selected) {
        request.headers = request.headers || {};
        request.headers['Accept-Profile'] = selected.name;
        request.headers['Content-Profile'] = selected.name;
      }
      return request;
    }
  });
};
`);
JS

# The image serves precompressed assets when the browser accepts gzip.
gzip -c /usr/share/nginx/html/swagger-initializer.js > /usr/share/nginx/html/swagger-initializer.js.gz

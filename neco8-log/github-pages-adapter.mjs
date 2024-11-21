import * as fs from "fs";

export default async function run({
  renderFunctionFilePath,
  routePatterns,
  apiRoutePatterns,
}) {
  console.log("Running GitHub Pages adapter");

  // Ensure dist directory exists
  ensureDirSync("dist");

  // Create .nojekyll to disable Jekyll processing
  fs.writeFileSync("dist/.nojekyll", "");

  // Copy render function
  fs.copyFileSync(renderFunctionFilePath, "./dist/elm-pages-cli.mjs");

  // Create 404.html for SPA routing
  fs.writeFileSync(
    "dist/404.html",
    `<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Single Page Apps for GitHub Pages</title>
    <script type="text/javascript">
      // SPA Redirect Script
      (function(l) {
        if (l.search[1] === '/' ) {
          var decoded = l.search.slice(1).split('&').map(function(s) { 
            return s.replace(/~and~/g, '&')
          }).join('?');
          window.history.replaceState(null, null,
              l.pathname.slice(0, -1) + decoded + l.hash
          );
        }
      }(window.location))
    </script>
  </head>
  <body>
  </body>
</html>`
  );
}

function ensureDirSync(dirpath) {
  try {
    fs.mkdirSync(dirpath, { recursive: true });
  } catch (err) {
    if (err.code !== "EEXIST") throw err;
  }
}

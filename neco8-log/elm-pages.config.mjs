import { defineConfig } from "vite";
import adapter from "elm-pages/adapter/netlify.js";

export default {
  vite: defineConfig({
    build: {
      // GitHub Pagesのベースパスに合わせる
      base: "/neco8.log/",
      // ビルド出力の設定
      outDir: "dist",
      // elm-pagesのビルド出力を直接distに配置
      rollupOptions: {
        input: {
          main: "elm-stuff/elm-pages/index.html",
        },
        output: {
          dir: "dist",
          // アセットのファイル名パターン
          assetFileNames: "assets/[name]-[hash][extname]",
          entryFileNames: "assets/[name]-[hash].js",
        },
      },
    },
  }),
  adapter,
  headTagsTemplate(context) {
    return `
<link rel="stylesheet" href="/style.css" />
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Shippori+Mincho+B1&display=swap" rel="stylesheet">
<meta name="generator" content="elm-pages v${context.cliVersion}" />
`;
  },
  preloadTagForFile(file) {
    // add preload directives for JS assets and font assets, etc., skip for CSS files
    // this function will be called with each file that is procesed by Vite, including any files in your headTagsTemplate in your config
    return !file.endsWith(".css");
  },
};

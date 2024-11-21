import { defineConfig } from "vite";
import adapter from "./github-pages-adapter.mjs";

export default {
  vite: defineConfig({
    build: {
      // 出力を最小限に
      outDir: "../dist",
      emptyOutDir: true,
      // 必要最小限のファイルのみ出力
      rollupOptions: {
        output: {
          entryFileNames: "assets/[name].js",
          chunkFileNames: "assets/[name].js",
          assetFileNames: "assets/[name][extname]",
        },
      },
      // アセットの最適化
      minify: true,
      sourcemap: false,
    },
    // 静的アセットの処理
    assetsInclude: ["**/*.elm"],
    // プラグインの設定
    plugins: [],
    // GitHub Pages用のベースパス設定
    base: "/neco8.log/",
  }),
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

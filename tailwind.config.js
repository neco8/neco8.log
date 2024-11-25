/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./src/**/*.{elm,js,html}",
    "./index.html",
    "./.elm-pages/**/*.{js,html}",  // 生成されたファイルを監視
    "./app/**/*.{elm,js,html}",     // appディレクトリも監視
    "./dist/**/*.{html,js}"         // ビルド後のファイルも監視
  ],
  theme: {
    extend: {
      fontFamily: {
        'mincho': ['"Shippori Mincho B1"', 'serif'],
      },
    },
  },
  plugins: [],
}


import fs from "fs/promises";
import path from "path";
import fg from "fast-glob";
import matter from "gray-matter";

/**
 * @typedef {Object} ConversionRule
 * @property {string} before - 元のメタデータキーまたは"fileName"
 * @property {string} after - 変換後のメタデータキーまたは"fileName"
 */

/**
 * @typedef {Object} ConversionParams
 * @property {string} sourceDir - ソースディレクトリのパス
 * @property {string} destDir - ディスティネーションディレクトリのパス
 * @property {ConversionRule[]} rules - 変換ルールの配列
 */

/**
 * 指定されたルールに基づいてMarkdownファイルを変換します。
 * @param {ConversionParams} params
 * @returns {Promise<Array<{success: boolean, source: string, destination: string}>>}
 */
export async function convertMarkdownFiles(params) {
  console.log("Markdownファイルを変換中...");
  const sourcePath = path.resolve(process.cwd(), params.sourceDir);
  const destinationPath = path.resolve(process.cwd(), params.destDir);

  try {
    // ディスティネーションディレクトリが存在しない場合は作成
    await fs.mkdir(destinationPath, { recursive: true });

    // ソースディレクトリ内のすべての.mdファイルを検索
    const files = await fg("**/*.md", { cwd: sourcePath });

    const results = await Promise.all(
      files.map(async (file) => {
        try {
          const sourceFilePath = path.join(sourcePath, file);
          const content = await fs.readFile(sourceFilePath, "utf-8");

          // フロントマターを解析
          const { data: frontmatter, content: markdownContent } =
            matter(content);

          // メタデータにfileNameを追加
          const metadata = {
            ...frontmatter,
            fileName: file,
          };

          // 変換ルールを適用
          const newMetadata = { ...metadata };
          for (const rule of params.rules) {
            // 元の値が存在しない場合はスキップ
            if (!(rule.before in metadata)) continue;

            if (rule.before === "fileName") {
              // 変換前がfileNameの場合、拡張子を取り除いたものを利用
              const baseFileName = path.parse(metadata.fileName).name;

              // 通常のメタデータ変換
              newMetadata[rule.after] = baseFileName;
            } else if (rule.after === "fileName") {
              // 変換後のキーがfileNameの場合の特別な処理
              const newFileName = metadata[rule.before];
              // 拡張子が.mdで終わるようにする
              const destFileName = newFileName.endsWith(".md")
                ? newFileName
                : `${newFileName}.md`;
              newMetadata.fileName = destFileName;
            } else {
              // 通常のメタデータ変換
              newMetadata[rule.after] = metadata[rule.before];
            }
          }

          // フロントマターからfileNameを削除
          const { fileName, ...newFrontmatter } = newMetadata;

          // 更新されたフロントマターで新しいコンテンツを作成
          const newContent = matter.stringify(markdownContent, newFrontmatter);

          // 新しい場所に書き込み
          const destFilePath = path.join(destinationPath, fileName);
          const destDir = path.dirname(destFilePath);

          // ディスティネーションのサブディレクトリが存在しない場合は作成
          await fs.mkdir(destDir, { recursive: true });

          // 新しいファイルを書き込み
          await fs.writeFile(destFilePath, newContent);

          return {
            success: true,
            source: file,
            destination: fileName,
          };
        } catch (error) {
          return {
            success: false,
            source: file,
            error: error.message,
          };
        }
      })
    );

    return results;
  } catch (error) {
    throw new Error(`ファイルの変換に失敗しました: ${error.message}`);
  }
}

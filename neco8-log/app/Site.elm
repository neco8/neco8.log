module Site exposing (config)

import BackendTask exposing (BackendTask)
import BackendTasks.ConvertMarkdownFiles as ConvertMarkdownFiles
import FatalError exposing (FatalError)
import Head
import SiteConfig exposing (SiteConfig)

config : SiteConfig
config =
    { canonicalUrl = "https://elm-pages.com"
    , head = head
    }

-- ファイル変換を行うBackendTask
convertFiles : BackendTask FatalError (List ConvertMarkdownFiles.ConversionResult)
convertFiles =
    ConvertMarkdownFiles.run
        { sourceDir = "obsidian"
        , destDir = "content/blog"
        , rules =
            [ { before = "fileName", after = "title" }
            , { before = "path", after = "fileName" }
            ]
        }

-- head タグを生成するBackendTask
head : BackendTask FatalError (List Head.Tag)
head =
    convertFiles
        |> BackendTask.andThen
            (\_ ->
                BackendTask.succeed
                    [ Head.metaName "viewport" (Head.raw "width=device-width,initial-scale=1")
                    , Head.sitemapLink "/sitemap.xml"
                    ]
            )
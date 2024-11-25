module Site exposing (config)

import BackendTask exposing (BackendTask)
import BackendTask.ConvertMarkdownFiles as ConvertMarkdownFiles
import FatalError exposing (FatalError)
import Head
import SiteConfig exposing (SiteConfig)


config : SiteConfig
config =
    { canonicalUrl = "https://neco8-log.netlify.app"
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
                    , Head.metaName "charset" (Head.raw "utf-8")
                    , Head.metaName "content-type" (Head.raw "text/html; charset=utf-8")
                    ]
            )

module MarkdownRenderer exposing (detailRenderer, omittedStringRenderer)

import Html exposing (Html, a, blockquote, br, code, div, em, h1, h2, h3, h4, hr, img, li, ol, p, pre, span, strong, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (alt, class, href, src)
import Markdown.Block as Block exposing (ListItem(..), Task(..))
import Markdown.Html
import Markdown.Renderer


detailRenderer : Markdown.Renderer.Renderer (Html msg)
detailRenderer =
    { heading =
        \{ level, children } ->
            case level of
                Block.H1 ->
                    h1
                        [ class "text-3xl mt-10 tracking-wide leading-relaxed text-stone-800" ]
                        children

                Block.H2 ->
                    h2
                        [ class "text-2xl mt-8 text-stone-800" ]
                        children

                Block.H3 ->
                    h3 [ class "text-xl mt-6 text-stone-700" ] children

                _ ->
                    h4 [ class "text-lg mt-2 text-stone-700" ] children
    , paragraph =
        \children ->
            p [ class "text-xs leading-relaxed text-stone-600" ] children
    , blockQuote =
        \children ->
            blockquote
                [ class "border-l-4 border-purple-600/10 grid grid-flow-row pl-4 italic" ]
                children
    , html = Markdown.Html.oneOf []
    , text = text
    , codeSpan =
        \txt ->
            code
                [ class "bg-purple-50 border border-purple-100 px-2 py-1 rounded text-xs" ]
                [ text txt ]
    , strong =
        \children -> strong [] children
    , emphasis =
        \children -> em [] children
    , strikethrough =
        \children ->
            span
                [ class "line-through"
                ]
                children
    , codeBlock =
        \{ body } ->
            div [ class "relative rounded-lg bg-purple-50 border border-purple-100 shadow-sm overflow-hidden" ]
                [ div [ class "flex items-center gap-2 px-4 py-3 border-b border-purple-100" ]
                    [ div [ class "w-3 h-3 rounded-full bg-violet-300" ] []
                    , div [ class "w-3 h-3 rounded-full bg-purple-300" ] []
                    , div [ class "w-3 h-3 rounded-full bg-indigo-300" ] []
                    ]
                , pre
                    [ class "p-4 font-mono text-xs overflow-x-auto bg-gradient-to-br from-purple-50 to-violet-50 text-slate-700" ]
                    [ code [] [ text body ]
                    ]
                ]
    , link =
        \{ destination } children ->
            a
                [ href destination
                , class "text-blue-600 hover:underline visited:text-purple-400 underline"
                ]
                children
    , image =
        \props ->
            img
                [ src props.src
                , alt props.alt
                , class "rounded-lg shadow-md"
                ]
                []
    , unorderedList =
        \items ->
            ul
                [ class "pl-3 text-stone-600 text-xs" ]
                (List.map
                    (\(ListItem task item) ->
                        let
                            { h, t } =
                                case item of
                                    head :: tail ->
                                        { h = head, t = tail }

                                    [] ->
                                        { h = text "", t = [] }
                        in
                        li [ class "relative pl-2" ]
                            (div
                                [ class "before:content-['•'] before:font-light before:absolute before:-left-1 before:text-stone-600 grid grid-flow-col py-2 items-start justify-start group"
                                ]
                                [ span
                                    [ case task of
                                        NoTask ->
                                            -- タスクがない場合は非表示
                                            class "hidden"

                                        IncompleteTask ->
                                            class "mr-2 group-hover:opacity-80 transition-opacity flex items-center aspect-square h-3 border rounded-sm border-stone-400 bg-white"

                                        CompletedTask ->
                                            class "mr-2 group-hover:opacity-80 transition-opacity flex items-center aspect-square h-3 border rounded-sm border-purple-400 bg-purple-600/30"
                                    ]
                                    []
                                , div
                                    -- タスクの内容用コンテナ
                                    [ class ""
                                    ]
                                    [ h ]
                                ]
                                :: t
                            )
                    )
                    items
                )
    , orderedList =
        \_ items ->
            ol
                [ class "pl-3 text-stone-600 text-xs" ]
                (List.indexedMap
                    (\idx item ->
                        let
                            { h, t } =
                                case item of
                                    head :: tail ->
                                        { h = head, t = tail }

                                    [] ->
                                        { h = text "", t = [] }
                        in
                        li [ class "relative pl-2 items-center" ]
                            [ div
                                [ class "relative grid grid-flow-col py-2 items-start justify-start group" ]
                                -- ここでマーカーを表示、select-noneでコピー不可に
                                [ span [ class "select-none absolute -left-1 -translate-x-full py-2" ]
                                    [ text <|
                                        String.fromInt (idx + 1)
                                            ++ "."
                                    ]
                                , span [] [ h ]
                                ]
                            , div [] t
                            ]
                    )
                    items
                )
    , table = table [ class "min-w-full" ]
    , tableHeader = thead []
    , tableBody = tbody []
    , tableRow = tr []
    , tableHeaderCell = \_ content -> th [ class "py-2 px-4 border-b" ] content
    , tableCell = \_ content -> td [ class "py-2 px-4 border-b" ] content
    , thematicBreak = hr [ class "my-8 border-t border-stone-200" ] []
    , hardLineBreak = br [] []
    }


omittedStringRenderer : Markdown.Renderer.Renderer String
omittedStringRenderer =
    { heading = .children >> String.join " "
    , paragraph = String.join " "
    , blockQuote = String.join " "
    , html = Markdown.Html.oneOf []
    , text = identity
    , codeSpan = identity
    , strong = String.join " "
    , emphasis = String.join " "
    , strikethrough = String.join " "
    , codeBlock = always " (...code) "
    , link = \_ -> String.join " "
    , image = .alt
    , unorderedList =
        \items ->
            String.join " " (List.map (\(Block.ListItem _ item) -> String.join " " item) items)
    , orderedList = \_ items -> String.join " " <| List.map (String.join " ") items
    , table = String.join " "
    , tableHeader = String.join " "
    , tableBody = String.join " "
    , tableRow = String.join " "
    , tableHeaderCell = \_ content -> String.join " " content
    , tableCell = \_ content -> String.join " " content
    , thematicBreak = ""
    , hardLineBreak = ""
    }

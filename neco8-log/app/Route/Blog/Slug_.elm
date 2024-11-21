module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import BlogPost exposing (BlogPost, blogPostDecoder)
import Date
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (..)
import Html.Attributes exposing (alt, class, href, src)
import Markdown.Block as Block exposing (ListItem(..))
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Pages.Url
import PagesMsg exposing (PagesMsg)
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    { slug : String }


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { head = head
        , pages = pages
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Glob.succeed (\_ slug -> { slug = slug })
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


type alias Data =
    { post : BlogPost }


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    File.bodyWithFrontmatter blogPostDecoder
        ("content/blog/" ++ routeParams.slug ++ ".md")
        |> BackendTask.allowFatal
        |> BackendTask.map Data


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "My Blog"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "Blog logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = app.data.post.content |> String.left 160
        , locale = Nothing
        , title = app.data.post.title
        }
        |> Seo.website


customRenderer : Markdown.Renderer.Renderer (Html msg)
customRenderer =
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
                [ class "bg-stone-100 px-2 py-1 rounded text-sm" ]
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
        \{ body, language } ->
            div [ class "relative rounded-lg bg-purple-50 border border-purple-100 shadow-sm overflow-hidden" ]
                [ div [ class "flex items-center gap-2 px-4 py-3 border-b border-purple-100" ]
                    [ div [ class "w-3 h-3 rounded-full bg-violet-300" ] []
                    , div [ class "w-3 h-3 rounded-full bg-purple-300" ] []
                    , div [ class "w-3 h-3 rounded-full bg-indigo-300" ] []
                    ]
                , pre
                    [ class "p-4 font-mono text-sm overflow-x-auto bg-gradient-to-br from-purple-50 to-violet-50 text-slate-700" ]
                    [ code [ class "text-sm" ] [ text body ]
                    ]
                ]
    , link =
        \{ destination } children ->
            a
                [ href destination
                , class "text-purple-600 hover:underline"
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
                [ class "list-disc pl-5 space-y-2" ]
                (List.map (\(ListItem _ item) -> li [] item) items)
    , orderedList =
        \idx items ->
            ol
                [ class "list-decimal pl-5 space-y-2" ]
                (List.map (\item -> li [] item) items)
    , table = table [ class "min-w-full" ]
    , tableHeader = thead []
    , tableBody = tbody []
    , tableRow = tr []
    , tableHeaderCell = \_ content -> th [ class "py-2 px-4 border-b" ] content
    , tableCell = \_ content -> td [ class "py-2 px-4 border-b" ] content
    , thematicBreak = hr [ class "my-8 border-t border-stone-200" ] []
    , hardLineBreak = br [] []
    }


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    { title = app.data.post.title
    , body =
        [ article [ class "" ]
            [ h1
                [ class "text-3xl mt-10 tracking-wide leading-relaxed text-stone-800" ]
                [ text app.data.post.title ]
            , div [ class "text-xs text-stone-400 tracking-wider" ]
                [ text <| Date.format "yyyy年M月d日" app.data.post.published ]
            , case
                app.data.post.content
                    |> Markdown.Parser.parse
                    |> Result.mapError (\_ -> "Markdown parsing failed")
                    |> Result.andThen
                        (\blocks ->
                            Markdown.Renderer.render customRenderer blocks
                                |> Result.mapError (\_ -> "Markdown rendering failed")
                        )
              of
                Ok rendered ->
                    div [ class "gap-4 grid grid-flow-row" ] rendered

                Err error ->
                    div [ class "text-red-500" ]
                        [ text error ]
            , nav [ class "border-t border-stone-200 mt-16 pt-12 flex justify-between text-xs text-gray-500" ]
                [ a [ href "#", class "hover:text-black" ]
                    [ text "← 前の記事" ]
                , a [ href "#", class "hover:text-black" ]
                    [ text "次の記事 →" ]
                ]
            ]
        ]
    }

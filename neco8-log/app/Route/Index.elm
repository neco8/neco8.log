module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File exposing (bodyWithFrontmatter)
import BackendTask.Glob as Glob
import BlogPost exposing (BlogPost, blogPostDecoder)
import Date
import Elm.Let exposing (letIn)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes
import Markdown.Block as Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Pages.Url
import PagesMsg exposing (PagesMsg)
import Route
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import UrlPath
import View exposing (View)


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


type alias Data =
    { blogPosts :
        List
            { slug : String
            , post : BlogPost
            }
    }


type alias ActionData =
    {}


route : StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildNoState { view = view }


customRenderer : Markdown.Renderer.Renderer String
customRenderer =
    { heading = .children >> String.join " "
    , paragraph = String.join " "
    , blockQuote = String.join " "
    , html = Markdown.Html.oneOf []
    , text = identity
    , codeSpan = identity
    , strong = String.join " "
    , emphasis = String.join " "
    , strikethrough = String.join " "
    , codeBlock = (always " (...code) ")
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


data : BackendTask FatalError Data
data =
    Glob.succeed (\filePath slug -> { filePath = filePath, slug = slug })
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask
        |> BackendTask.andThen
            (List.map
                (\file ->
                    bodyWithFrontmatter blogPostDecoder file.filePath
                        |> BackendTask.mapError .fatal
                        |> BackendTask.map (\post -> { slug = file.slug, post = post })
                )
                >> BackendTask.sequence
                >> BackendTask.map Data
            )


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = [ "images", "icon-png.png" ] |> UrlPath.join |> Pages.Url.fromPath
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Welcome to elm-pages!"
        , locale = Nothing
        , title = "elm-pages is running"
        }
        |> Seo.website


trim : String -> String
trim s =
    let
        len =
            200
    in
    if String.length s > len then
        String.left len s ++ "……"

    else
        s


viewArticle : { post : BlogPost, slug : String } -> Html.Html msg
viewArticle { post, slug } =
    Html.article
        []
        [ Html.time
            [ Html.Attributes.class "text-xs tracking-wider text-stone-400" ]
            [ Html.text <| Date.format "yyyy年M月d日" post.published ]
        , Html.h2
            [ Html.Attributes.class "mt-1 text-base text-stone-900 tracking-wider leading-normal" ]
            [ Html.a
                [ Html.Attributes.href <| "/blog/" ++ slug, Html.Attributes.class "hover:text-stone-600" ]
                [ Html.text post.title ]
            ]
        , Html.p
            [ Html.Attributes.class "mt-2 text-xs leading-relaxed text-stone-600" ]
            [ case
                post.content
                    |> Markdown.Parser.parse
                    |> Result.mapError (always "Markdown parsing failed")
                    |> Result.andThen
                        (\blocks ->
                            Markdown.Renderer.render customRenderer blocks
                                |> Result.mapError (always "Markdown rendering failed")
                                |> Result.map (String.join " " >> trim)
                        )
              of
                Ok rendered ->
                    Html.text rendered

                Err error ->
                    Html.text error
            ]
        , Html.div
            [ Html.Attributes.class "mt-4 text-xs" ]
            [ Html.a
                [ Html.Attributes.href <| "/blog/" ++ slug, Html.Attributes.class "text-stone-400 transition-colors duration-500 hover:text-stone-800" ]
                [ Html.text "続きを読む →" ]
            ]
        ]


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app shared =
    { title = "elm-pages is running"
    , body =
        List.map viewArticle app.data.blogPosts
    }

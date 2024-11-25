module BlogPost exposing (BlogPost, blogPostDecoder, getAroundPost, getBlogPosts, omitAndTrim, trim, viewPost, viewPostDetail)

import BackendTask
import BackendTask.File exposing (bodyWithFrontmatter)
import BackendTask.Glob as Glob
import Date exposing (Date)
import Elm.Let exposing (letIn)
import FatalError exposing (FatalError)
import Html exposing (Html, a, article, div, h1, nav, text)
import Html.Attributes exposing (class, href)
import Json.Decode as Decode exposing (Decoder)
import List.Extra
import Markdown.Parser
import Markdown.Renderer
import MarkdownRenderer exposing (detailRenderer, omittedStringRenderer)


type alias BlogPost =
    { content : String
    , tags : List String
    , published : Date
    , title : String
    }


dateDecoder : Decoder Date
dateDecoder =
    Decode.string
        |> Decode.andThen
            (\str ->
                case Date.fromIsoString str of
                    Ok date ->
                        Decode.succeed date

                    Err _ ->
                        Decode.fail "Invalid date"
            )


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


blogPostDecoder : String -> Decoder BlogPost
blogPostDecoder body =
    Decode.map4 BlogPost
        (Decode.succeed body)
        (Decode.field "tags" (Decode.list Decode.string))
        (Decode.field "published" dateDecoder)
        (Decode.field "title" Decode.string)


omitAndTrim : String -> String
omitAndTrim content =
    case
        content
            |> Markdown.Parser.parse
            |> Result.mapError (always "Markdown parsing failed")
            |> Result.andThen
                (\blocks ->
                    Markdown.Renderer.render omittedStringRenderer blocks
                        |> Result.mapError (always "Markdown rendering failed")
                        |> Result.map (String.join " " >> trim)
                )
    of
        Ok rendered ->
            rendered

        Err error ->
            error


viewPost : { post : BlogPost, slug : String } -> Html msg
viewPost { post, slug } =
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
            [ omitAndTrim post.content
                |> Html.text
            ]
        , Html.div
            [ Html.Attributes.class "mt-4 text-xs" ]
            [ Html.a
                [ Html.Attributes.href <| "/blog/" ++ slug, Html.Attributes.class "text-stone-400 transition-colors duration-500 hover:text-stone-800" ]
                [ Html.text "続きを読む →" ]
            ]
        ]


viewPostDetail : { post : BlogPost, around : { prev : Maybe { slug : String, post : BlogPost }, next : Maybe { slug : String, post : BlogPost } } } -> Html msg
viewPostDetail { post, around } =
    article []
        [ h1
            [ class "text-3xl mt-10 tracking-wide leading-relaxed text-stone-800" ]
            [ text post.title ]
        , div [ class "text-xs text-stone-400 tracking-wider" ]
            [ text <| Date.format "yyyy年M月d日" post.published ]
        , case
            post.content
                |> Markdown.Parser.parse
                |> Result.mapError (\_ -> "Markdown parsing failed")
                |> Result.andThen
                    (\blocks ->
                        Markdown.Renderer.render detailRenderer blocks
                            |> Result.mapError (\_ -> "Markdown rendering failed")
                    )
          of
            Ok rendered ->
                div [ class "gap-4 grid grid-flow-row mt-10" ] rendered

            Err error ->
                div [ class "text-red-500" ]
                    [ text error ]
        , nav [ class "border-t border-stone-200 mt-16 pt-12 flex justify-between text-xs text-gray-500" ] <|
            let
                { prev, next } =
                    around
            in
            [ a
                (case prev of
                    Just { slug } ->
                        [ href <| "/blog/" ++ slug, class "hover:text-black" ]

                    Nothing ->
                        [ class "pointer-events-none invisible" ]
                )
                [ text "← 前の記事" ]
            , a
                (case next of
                    Just { slug } ->
                        [ href <| "/blog/" ++ slug, class "hover:text-black" ]

                    Nothing ->
                        [ class "pointer-events-none invisible" ]
                )
                [ text "次の記事 →" ]
            ]
        ]


getBlogPosts : BackendTask.BackendTask FatalError (List { slug : String, post : BlogPost })
getBlogPosts =
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
                        |> BackendTask.allowFatal
                        |> BackendTask.map (\post -> { slug = file.slug, post = post })
                )
                >> BackendTask.sequence
            )


getAroundPost : String -> BackendTask.BackendTask FatalError { prev : Maybe { slug : String, post : BlogPost }, next : Maybe { slug : String, post : BlogPost } }
getAroundPost slug =
    getBlogPosts
        |> BackendTask.andThen
            (List.sortBy (.post >> .published >> Date.toRataDie)
                >> List.Extra.splitWhen (.slug >> (==) slug)
                >> Maybe.map (Tuple.mapBoth List.Extra.last (List.tail >> Maybe.andThen List.head))
                >> Maybe.andThen
                    (\( prev, next ) ->
                        Just <|
                            BackendTask.succeed
                                { prev = prev
                                , next = next
                                }
                    )
                >> Maybe.withDefault
                    (BackendTask.fail
                        (FatalError.build
                            { title = "Blog post not found"
                            , body = "The blog post with the slug " ++ slug ++ " was not found."
                            }
                        )
                    )
            )

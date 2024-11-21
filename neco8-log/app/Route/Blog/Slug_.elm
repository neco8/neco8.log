module Route.Blog.Slug_ exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.File as File
import BackendTask.Glob as Glob
import BlogPost exposing (BlogPost, blogPostDecoder, getAroundPost, omitAndTrim, viewPostDetail)
import Elm.Let exposing (letIn)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html exposing (..)
import Markdown.Block exposing (ListItem(..))
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
    { post : BlogPost
    , around : { prev : Maybe { slug : String, post : BlogPost }, next : Maybe { slug : String, post : BlogPost } }
    }


type alias ActionData =
    {}


data : RouteParams -> BackendTask FatalError Data
data routeParams =
    BackendTask.succeed Data
        |> BackendTask.andMap
            (File.bodyWithFrontmatter
                blogPostDecoder
                ("content/blog/" ++ routeParams.slug ++ ".md")
                |> BackendTask.allowFatal
            )
        |> BackendTask.andMap (getAroundPost routeParams.slug)


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head app =
    let
        seo =
            Shared.seo
    in
    Seo.summary
        { seo
            | description = app.data.post.content |> omitAndTrim
            , title = app.data.post.title
        }
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = app.data.post.title
    , body =
        [ viewPostDetail app.data
        ]
    }

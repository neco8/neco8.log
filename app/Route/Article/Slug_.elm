module Route.Article.Slug_ exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask exposing (BackendTask)
import BackendTask.Glob as Glob
import BlogPost exposing (omitAndTrim)
import ErrorPage
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import Html
import PagesMsg
import RouteBuilder
import Server.Request
import Server.Response
import Shared
import View


type alias Model =
    {}


type alias Msg
    = ()


type alias RouteParams =
    { slug : String }


route : RouteBuilder.StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.preRender
        { data = data
        , head = head
        , pages = pages
        }
        |> RouteBuilder.buildNoState
            { view = view
            }


pages : BackendTask FatalError (List RouteParams)
pages =
    Glob.succeed (\_ slug -> { slug = slug })
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


type alias Data =
    {}


type alias ActionData =
    {}


data :
    RouteParams
    -> BackendTask.BackendTask FatalError.FatalError Data
data routeParams =
    BackendTask.succeed {}


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    let
        seo =
            Shared.seo
    in
    Seo.summary
        { seo
            | description = "" |> omitAndTrim -- TODO: ここで記事を取得する
            , title = ""
        }
        |> Seo.website


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> View.View (PagesMsg.PagesMsg msg)
view app shared =
    { title = "Article.Slug_", body = [ Html.h2 [] [ Html.text "New Page" ] ] }


action :
    RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action routeParams request =
    BackendTask.succeed (Server.Response.render {})

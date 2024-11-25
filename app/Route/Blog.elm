module Route.Blog exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask exposing (BackendTask)
import BackendTask.Glob as Glob
import ErrorPage
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
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
    {}


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
    Glob.succeed (\_ -> {})
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.match Glob.wildcard
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
    Shared.seo
        |> Seo.summary
        |> Seo.website


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> View.View (PagesMsg.PagesMsg msg)
view app shared =
    { title = "Blog", body = [] }


action :
    RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action routeParams request =
    BackendTask.succeed (Server.Response.render {})

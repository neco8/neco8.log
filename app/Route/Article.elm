module Route.Article exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import Effect
import ErrorPage
import FatalError
import Head
import Head.Seo as Seo
import PagesMsg
import RouteBuilder
import Server.Request
import Server.Response
import Shared
import UrlPath
import View


type alias Model =
    {}


type alias Msg =
    ()


type alias RouteParams =
    {}


route : RouteBuilder.StatelessRoute RouteParams Data ActionData
route =
    RouteBuilder.serverRender
        { data = data
        , action = action
        , head = head
        }
        |> RouteBuilder.buildNoState
            { view = view
            }


init :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect.Effect Msg )
init app shared =
    ( {}, Effect.none )


subscriptions : RouteParams -> UrlPath.UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions routeParams path shared model =
    Sub.none


type alias Data =
    {}


type alias ActionData =
    {}


data :
    RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response Data ErrorPage.ErrorPage)
data routeParams request =
    BackendTask.succeed (Server.Response.render {})


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head app =
    Shared.seo
        |> Seo.summary
        |> Seo.website


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> View.View (PagesMsg.PagesMsg Msg)
view app shared =
    { title = "Article", body = [] }


action :
    RouteParams
    -> Server.Request.Request
    -> BackendTask.BackendTask FatalError.FatalError (Server.Response.Response ActionData ErrorPage.ErrorPage)
action routeParams request =
    BackendTask.succeed (Server.Response.render {})

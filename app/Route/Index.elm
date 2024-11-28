module Route.Index exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import BackendTask.Glob as Glob
import BlogPost exposing (BlogPost, getBlogPosts, viewPost)
import FatalError exposing (FatalError)
import Head
import Head.Seo as Seo
import PagesMsg exposing (PagesMsg)
import Route
import RouteBuilder exposing (App, StatelessRoute)
import Shared
import View exposing (View)
import List.Extra
import Date


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
    RouteBuilder.preRender
        { head = head
        , data = data
        , pages = pages
        }
        |> RouteBuilder.buildNoState { view = view }


pages : BackendTask FatalError (List RouteParams)
pages =
    Glob.succeed (\_ -> {})
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "content/blog/")
        |> Glob.match Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toBackendTask


data : RouteParams -> BackendTask FatalError Data
data _ =
    getBlogPosts
        |> BackendTask.map Data


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    Shared.seo
        |> Seo.summary
        |> Seo.website


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> View (PagesMsg Msg)
view app _ =
    { title = Shared.title
    , body =
        List.map viewPost
            <| List.sortBy (\d -> d.post.published |> Date.toRataDie |> negate) app.data.blogPosts
    }

module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import BackendTask exposing (BackendTask)
import Effect exposing (Effect)
import FatalError exposing (FatalError)
import Html exposing (Html)
import Html.Attributes
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import UrlPath exposing (UrlPath)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Nothing
    }


type Msg
    = SharedMsg SharedMsg


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    {}


init :
    Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : UrlPath
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Effect Msg )
init flags maybePagePath =
    ( {}
    , Effect.none
    )


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SharedMsg globalMsg ->
            ( model, Effect.none )


subscriptions : UrlPath -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : BackendTask FatalError Data
data =
    BackendTask.succeed ()


title : String
title =
    "neco8.log"


view :
    Data
    ->
        { path : UrlPath
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : List (Html msg), title : String }
view sharedData page model toMsg pageView =
    { body =
        [ Html.div
            [ Html.Attributes.class "min-h-screen bg-stone-50 font-mincho" ]
            [ Html.header
                [ Html.Attributes.class "py-8" ]
                [ Html.div
                    [ Html.Attributes.class "px-4 grid place-items-center" ]
                    [ Html.a
                        [ Html.Attributes.class "justify-center text-[160px] max-lg:text-8xl text-nowrap text-center text-stone-800"
                        , Html.Attributes.href "/"
                        ]
                        [ Html.text title ]
                    , Html.nav
                        [ Html.Attributes.class "w-full px-4 max-lg:mt-6 mb-20 border-y border-stone-200" ]
                        [ Html.ul
                            [ Html.Attributes.class "flex justify-center space-x-8 py-2 text-xs tracking-widest text-stone-600" ]
                            [ Html.li []
                                [ Html.a
                                    [ Html.Attributes.href "/", Html.Attributes.class "hover:text-stone-900" ]
                                    [ Html.text "ホーム" ]
                                ]
                            , Html.li []
                                [ Html.a
                                    [ Html.Attributes.href "/about", Html.Attributes.class "hover:text-stone-900" ]
                                    [ Html.text "概要" ]
                                ]
                            , Html.li []
                                [ Html.a
                                    [ Html.Attributes.href "/archive", Html.Attributes.class "hover:text-stone-900" ]
                                    [ Html.text "記録" ]
                                ]
                            ]
                        ]
                    ]
                ]
            , Html.main_
                [ Html.Attributes.class "max-w-xl mx-auto px-4 py-8 space-y-10" ]
                pageView.body
            , Html.footer
                [ Html.Attributes.class "py-8" ]
                [ Html.div
                    [ Html.Attributes.class "max-w-xl mx-auto px-4" ]
                    [ Html.p
                        [ Html.Attributes.class "text-center text-xs tracking-wide text-stone-500" ]
                        [ Html.text <| "© 2024 " ++ title ]
                    ]
                ]
            ]
        ]
    , title = pageView.title
    }

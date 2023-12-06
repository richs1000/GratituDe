module Page.EnhanceYou exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Http


type alias ModelEY =
    {}


initModelEY =
    {}


type MsgEY
    = NoOp


initEY : ( ModelEY, Cmd MsgEY )
initEY =
    ( initModelEY
    , Cmd.none
    )


updateEY : MsgEY -> ModelEY -> ( ModelEY, Cmd MsgEY )
updateEY msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


viewEY : ModelEY -> Html MsgEY
viewEY model =
    div []
        [ div []
            [ h3 [] [ text "Podcasts" ]
            ]
        , div []
            [ h3 [] [ text "Social Media Accounts" ]
            ]
        , div []
            [ h3 [] [ text "Inspirational Text" ]
            ]
        ]

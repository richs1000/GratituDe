module Page.EditUser exposing (..)

{-
   https://elmprogramming.com/editing-a-post.html
-}

import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import RemoteData as RD
import User


type alias ModelEU =
    { navKey : Nav.Key
    , user : RD.WebData User.User
    }


initialModelEU : Nav.Key -> ModelEU
initialModelEU navKeyParam =
    { navKey = navKeyParam
    , user = RD.Loading
    }


initEU : User.UserId -> Nav.Key -> ( ModelEU, Cmd MsgEU )
initEU userId navKey =
    ( initialModelEU navKey, fetchUser userId )


fetchUser : User.UserId -> Cmd MsgEU
fetchUser userId =
    Http.get
        { url = "http://localhost:5019/users/" ++ User.userIdToString userId
        , expect =
            User.userDecoder
                -- func1 >> func2 == \param -> func2 (fun1 param)
                -- RD.fromResult >> UserReceived = \p -> UserReceived (RD.fromResult p)
                |> Http.expectJson (RD.fromResult >> UserReceived)
        }


type MsgEU
    = UserReceived (RD.WebData User.User)


updateEU : MsgEU -> ModelEU -> ( ModelEU, Cmd MsgEU )
updateEU msg model =
    case msg of
        UserReceived serverResponse ->
            ( { model | user = serverResponse }
            , Cmd.none
            )


viewEU : ModelEU -> Html MsgEU
viewEU model =
    div []
        [ h3 [] [ text "Form goes here" ] ]

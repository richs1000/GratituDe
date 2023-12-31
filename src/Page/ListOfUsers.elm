module Page.ListOfUsers exposing (..)

{-
   elm install elm/http
   elm install krisajenkins/remotedata
-}
--import Json.Decode as Decode

import ErrorMessages as EM
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Http
import RemoteData as RD
import User



{-
   https://elmprogramming.com/creating-list-posts-page.html
   https://elmprogramming.com/editing-a-post.html
-}


type alias ModelLoU =
    { users : RD.WebData (List User.User)
    }


initModelLoU : ModelLoU
initModelLoU =
    { users = RD.Loading
    }


type MsgLoU
    = FetchUsers
    | UsersReceived (RD.WebData (List User.User))


initLoU : ( ModelLoU, Cmd MsgLoU )
initLoU =
    ( initModelLoU
    , fetchUsers
    )


fetchUsers : Cmd MsgLoU
fetchUsers =
    Http.get
        { url = "http://localhost:5019/users"
        , expect =
            User.listOfUsersDecoder
                |> Http.expectJson (RD.fromResult >> UsersReceived)
        }


updateLoU : MsgLoU -> ModelLoU -> ( ModelLoU, Cmd MsgLoU )
updateLoU msg model =
    case msg of
        FetchUsers ->
            ( { model | users = RD.Loading }
            , fetchUsers
            )

        UsersReceived responseFromServer ->
            ( { model | users = responseFromServer }
            , Cmd.none
            )


viewLoU : ModelLoU -> Html MsgLoU
viewLoU model =
    div []
        [ button [ Events.onClick FetchUsers ]
            [ text "Refresh Users" ]
        , viewListOfUsers model.users
        ]


viewListOfUsers : RD.WebData (List User.User) -> Html MsgLoU
viewListOfUsers users =
    case users of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading..." ]

        RD.Success listOfUsers ->
            div []
                [ h3 [] [ text "Registered Users" ]
                , table []
                    (viewTableHeader :: List.map viewUser listOfUsers)
                ]

        RD.Failure httpError ->
            viewFetchError (EM.buildErrorMessage httpError)


viewUser : User.User -> Html MsgLoU
viewUser user =
    let
        userPath =
            "/users/" ++ User.userIdToString user.id
    in
    tr []
        [ td []
            [ text (User.userIdToString user.id) ]
        , td []
            [ text (User.userNameToString user.name) ]
        , td []
            [ text (User.userEmailToString user.email) ]
        , td []
            [ text (User.completedChallengesToString user.completedChallenges) ]
        , td []
            [ a [ href userPath ] [ text "Edit" ] ]
        ]


viewTableHeader : Html MsgLoU
viewTableHeader =
    tr []
        [ th []
            [ text "ID" ]
        , th []
            [ text "Name" ]
        , th []
            [ text "Email" ]
        , th []
            [ text "Completed Challenges" ]
        ]


viewFetchError : String -> Html MsgLoU
viewFetchError errorMessage =
    let
        errorHeading =
            "Couldn't fetch users at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]

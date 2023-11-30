module Page.EditUser exposing (..)

{-
   To Do:
   * edit completed challenges
   * Validate user input
   https://package.elm-lang.org/packages/rtfeldman/elm-validate/latest/

-}
{-
   https://elmprogramming.com/editing-a-post.html
-}

import Browser.Navigation as Nav
import ErrorMessages as EM
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick, onInput)
import Http
import RemoteData as RD
import Route
import User


type alias ModelEU =
    { navKey : Nav.Key
    , user : RD.WebData User.User
    , saveError : Maybe String
    }


initialModelEU : Nav.Key -> ModelEU
initialModelEU navKeyParam =
    { navKey = navKeyParam
    , user = RD.Loading
    , saveError = Nothing
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
    | UpdateUserName String
    | UpdateUserEmail String
    | UpdateUserPassword String
    | SaveUser
      -- UserSaved payload doesn’t need to be of type WebData because we aren’t interested
      -- in tracking all the states our PATCH request goes through
    | UserSaved (Result Http.Error User.User)


updateEU : MsgEU -> ModelEU -> ( ModelEU, Cmd MsgEU )
updateEU msg model =
    case msg of
        UserReceived serverResponse ->
            ( { model | user = serverResponse }
            , Cmd.none
            )

        UpdateUserName newUserName ->
            let
                -- Create a new user record
                updatedUserRecord =
                    -- The user record is stored within a RemoteData type
                    -- RD.map : (a -> b) -> RemoteData e a -> RemoteData e b
                    RD.map
                        -- (a -> b) ==> User.User -> User.User
                        (\userData -> { userData | name = User.UserName newUserName })
                        -- RD.RemoteData e User.User
                        model.user
            in
            -- Replace the old model with the new model (with updated name)
            ( { model | user = updatedUserRecord }
            , Cmd.none
            )

        UpdateUserEmail newUserEmail ->
            let
                -- Create a new user record
                updatedUserRecord =
                    -- The user record is stored within a RemoteData type
                    -- RD.map : (a -> b) -> RemoteData e a -> RemoteData e b
                    RD.map
                        -- (a -> b) ==> User.User -> User.User
                        (\userData -> { userData | email = User.UserEmail newUserEmail })
                        -- RD.RemoteData e User.User
                        model.user
            in
            -- Replace the old model with the new model (with updated name)
            ( { model | user = updatedUserRecord }
            , Cmd.none
            )

        UpdateUserPassword newUserPassword ->
            let
                -- Create a new user record
                updatedUserRecord =
                    -- The user record is stored within a RemoteData type
                    -- RD.map : (a -> b) -> RemoteData e a -> RemoteData e b
                    RD.map
                        -- (a -> b) ==> User.User -> User.User
                        (\userData -> { userData | password = User.UserPassword newUserPassword })
                        -- RD.RemoteData e User.User
                        model.user
            in
            -- Replace the old model with the new model (with updated name)
            ( { model | user = updatedUserRecord }
            , Cmd.none
            )

        SaveUser ->
            ( model, saveUser model.user )

        UserSaved (Ok userData) ->
            let
                savedUser =
                    RD.succeed userData
            in
            ( { model | user = savedUser, saveError = Nothing }
            , Route.pushUrl Route.ListOfUsersRoute model.navKey
            )

        UserSaved (Err error) ->
            ( { model | saveError = Just (EM.buildErrorMessage error) }
            , Cmd.none
            )


saveUser : RD.WebData User.User -> Cmd MsgEU
saveUser user =
    case user of
        RD.Success userData ->
            let
                userUrl =
                    "http://localhost:5019/users/"
                        ++ User.userIdToString userData.id
            in
            Http.request
                -- PATCH means update a resource already on the server
                { method = "PATCH"

                -- No additional information to the server
                , headers = []

                -- Location of the resource we want to modify
                , url = userUrl

                -- Updated user data (that has been converted to JSON)
                -- This will add the Content-Type: application/json header
                -- to our HTTP request behind the scenes. That is how the
                -- server knows the body of a request is in JSON format.
                , body = Http.jsonBody (User.userEncoder userData)

                -- we expect the response body to be JSON as well
                , expect = Http.expectJson UserSaved User.userDecoder

                -- Wait for the server forever
                , timeout = Nothing

                -- Do not track the progress of the request
                , tracker = Nothing
                }

        _ ->
            Cmd.none


viewEU : ModelEU -> Html MsgEU
viewEU model =
    div []
        [ h3 [] [ text "User Information" ]
        , viewUser model.user
        , viewSaveError model.saveError
        ]


viewUser : RD.WebData User.User -> Html MsgEU
viewUser user =
    case user of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading User Data..." ]

        RD.Success userData ->
            editUserForm userData

        RD.Failure httpError ->
            viewFetchError (EM.buildErrorMessage httpError)


editUserForm : User.User -> Html MsgEU
editUserForm user =
    Html.form []
        [ div []
            [ text "Name"
            , br [] []
            , input
                [ type_ "text"
                , value (User.userNameToString user.name)
                , onInput UpdateUserName
                ]
                []
            ]
        , br [] []

        -- , div []
        --     [ input
        --         [ type_ "checkbox"
        --         , checked True
        --         , name "myCB"
        --         ]
        --         []
        --     , label [ for "myCB" ]
        --         [ text "My first checkbox" ]
        --     ]
        , div []
            [ text "Email"
            , br [] []
            , input
                [ type_ "text"
                , value (User.userEmailToString user.email)
                , onInput UpdateUserEmail
                ]
                []
            ]
        , br [] []
        , div []
            [ text "Password"
            , br [] []
            , input
                [ type_ "text"
                , value (User.userPasswordToString user.password)
                , onInput UpdateUserPassword
                ]
                []
            ]
        , br [] []
        , div []
            [ button [ type_ "button", onClick SaveUser ]
                [ text "Submit" ]
            ]
        ]


viewSaveError : Maybe String -> Html msg
viewSaveError maybeError =
    case maybeError of
        Just error ->
            div []
                [ h3 [] [ text "Couldn't save post at this time." ]
                , text ("Error: " ++ error)
                ]

        Nothing ->
            text ""


viewFetchError : String -> Html MsgEU
viewFetchError errorMessage =
    let
        errorHeading =
            "Couldn't fetch post at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]

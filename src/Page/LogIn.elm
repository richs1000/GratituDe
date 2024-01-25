module Page.LogIn exposing (..)

{-
   https://elmprogramming.com/creating-a-new-post.html
-}

import Browser.Navigation as Nav
import ErrorMessages as EM
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import RemoteData as RD
import Route
import User


type alias ModelLI =
    { navKey : Nav.Key
    , userEmail : String
    , userPassword : String
    , newUser : Maybe User.User
    , allUsers : List User.User
    , logInError : Maybe String
    }


initLI : Nav.Key -> ( ModelLI, Cmd MsgLI )
initLI navKey =
    ( initialModelLI navKey, fetchUsers )


initialModelLI : Nav.Key -> ModelLI
initialModelLI navKeyParam =
    { navKey = navKeyParam
    , userEmail = ""
    , userPassword = ""
    , newUser = Nothing
    , allUsers = []
    , logInError = Nothing
    }


viewLI : ModelLI -> Html MsgLI
viewLI model =
    div []
        [ h3 [] [ text "Log In" ]
        , logInForm
        , viewError model.logInError
        ]


logInForm : Html MsgLI
logInForm =
    Html.form []
        [ div []
            [ text "Email"
            , br [] []
            , input [ type_ "text", onInput UpdateEmail ] []
            ]
        , br [] []
        , div []
            [ text "Password"
            , br [] []
            , input [ type_ "password", onInput UpdatePassword ] []
            ]
        , br [] []
        , div []
            [ button [ type_ "button", onClick LogInUser ]
                [ text "Log In" ]
            ]
        ]


viewError : Maybe String -> Html msg
viewError maybeError =
    case maybeError of
        Just error ->
            div []
                [ h3 [] [ text "Couldn't log in at this time." ]
                , text ("Error: " ++ error)
                ]

        Nothing ->
            text ""


type MsgLI
    = FetchUsers
    | UsersReceived (RD.WebData (List User.User))
    | UpdatePassword String
    | UpdateEmail String
    | LogInUser


updateLI : MsgLI -> ModelLI -> ( ModelLI, Cmd MsgLI )
updateLI msg model =
    case msg of
        --
        -- First thing we do, ask the server for all the email/password
        -- data for all the users. Yes, this is stupid.
        --
        FetchUsers ->
            ( model
            , fetchUsers
            )

        --
        -- Then the server responds and we save a list of all the users
        -- in our model
        --
        UsersReceived responseFromServer ->
            ( { model | allUsers = extractUsers responseFromServer }
            , Cmd.none
            )

        --
        -- User enter's email and password, model updates with each keystroke
        --
        UpdateEmail newEmail ->
            ( { model | userEmail = newEmail }, Cmd.none )

        UpdatePassword newPassword ->
            ( { model | userPassword = newPassword }, Cmd.none )

        --
        -- User click's the "log in" button. Compare the email and password
        -- the user entered with what's in our database
        --
        LogInUser ->
            let
                userMatch : User.User -> Bool
                userMatch userRecord =
                    model.userEmail
                        == User.userEmailToString userRecord.email
                        && model.userPassword
                        == User.userPasswordToString userRecord.password

                user : Maybe User.User
                user =
                    model.allUsers
                        |> List.filter userMatch
                        |> List.head
            in
            case user of
                Nothing ->
                    ( { model | newUser = user, logInError = Just "No matching user name and password" }
                    , Cmd.none
                    )

                Just u ->
                    ( { model | newUser = user, logInError = Nothing }
                    , Route.pushUrl (Route.UserRoute u.id) model.navKey
                    )



-- fetchUsers : Cmd MsgLI
-- fetchUsers =
--     Http.get
--         { url = "http://localhost:5019/users"
--         , expect =
--             User.listOfUsersDecoder
--                 |> Http.expectJson (RD.fromResult >> UsersReceived)
--         }
{-
   curl "https://teemingtooth.backendless.app/api/data/people?props=id,completedChallenges,name,password,objectId"

-}


fetchUsers : Cmd MsgLI
fetchUsers =
    Http.get
        { url = "https://teemingtooth.backendless.app/api/data/people"
        , expect =
            User.listOfUsersDecoder
                |> Http.expectJson (RD.fromResult >> UsersReceived)
        }


extractUsers : RD.WebData (List User.User) -> List User.User
extractUsers responseFromServer =
    case responseFromServer of
        RD.NotAsked ->
            []

        RD.Loading ->
            []

        RD.Success listOfUsers ->
            listOfUsers

        RD.Failure _ ->
            []

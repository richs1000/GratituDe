module Page.NewUser exposing (..)

{-
   https://elmprogramming.com/creating-a-new-post.html

   To Do:
   Validate user input
   https://package.elm-lang.org/packages/rtfeldman/elm-validate/latest/
-}

import Browser.Navigation as Nav
import ErrorMessages as EM
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Route
import User


type alias ModelNU =
    { navKey : Nav.Key
    , newUser : User.User
    , createError : Maybe String
    }


initialModelNU : Nav.Key -> ModelNU
initialModelNU navKeyParam =
    { navKey = navKeyParam
    , newUser = User.emptyUser
    , createError = Nothing
    }


initNU : Nav.Key -> ( ModelNU, Cmd MsgNU )
initNU navKey =
    ( initialModelNU navKey, Cmd.none )


viewNU : ModelNU -> Html MsgNU
viewNU model =
    div []
        [ h3 [] [ text "Create New User" ]
        , newUserForm
        , viewError model.createError
        ]


newUserForm : Html MsgNU
newUserForm =
    Html.form []
        [ div []
            [ text "Name"
            , br [] []
            , input [ type_ "text", onInput StoreName ] []
            ]
        , br [] []
        , div []
            [ text "Email"
            , br [] []
            , input [ type_ "text", onInput StoreEmail ] []
            ]
        , br [] []
        , div []
            [ text "Password"
            , br [] []
            , input [ type_ "password", onInput StoreEmail ] []
            ]
        , br [] []
        , div []
            [ button [ type_ "button", onClick CreateNewUser ]
                [ text "Submit" ]
            ]
        ]


viewError : Maybe String -> Html msg
viewError maybeError =
    case maybeError of
        Just error ->
            div []
                [ h3 [] [ text "Couldn't create a new user at this time." ]
                , text ("Error: " ++ error)
                ]

        Nothing ->
            text ""


type MsgNU
    = StoreName String
    | StoreEmail String
    | StorePassword String
    | CreateNewUser
    | NewUserCreated (Result Http.Error User.User)


updateNU : MsgNU -> ModelNU -> ( ModelNU, Cmd MsgNU )
updateNU msg model =
    case msg of
        StoreName newName ->
            let
                oldUserData =
                    model.newUser

                updatedUser =
                    { oldUserData | name = User.UserName newName }
            in
            ( { model | newUser = updatedUser }, Cmd.none )

        StoreEmail newEmail ->
            let
                oldUserData =
                    model.newUser

                updatedUser =
                    { oldUserData | email = User.UserEmail newEmail }
            in
            ( { model | newUser = updatedUser }, Cmd.none )

        StorePassword newPassword ->
            let
                oldUserData =
                    model.newUser

                updatedUser =
                    { oldUserData | password = User.UserPassword newPassword }
            in
            ( { model | newUser = updatedUser }, Cmd.none )

        CreateNewUser ->
            ( model, createNewUser model.newUser )

        NewUserCreated (Ok serverResponse) ->
            ( { model | newUser = serverResponse, createError = Nothing }
            , Route.pushUrl Route.ListOfUsersRoute model.navKey
            )

        NewUserCreated (Err error) ->
            ( { model | createError = Just (EM.buildErrorMessage error) }
            , Cmd.none
            )


createNewUser : User.User -> Cmd MsgNU
createNewUser newUser =
    Http.post
        { url = "http://localhost:5019/users"
        , body = Http.jsonBody (User.newUserEncoder newUser)
        , expect = Http.expectJson NewUserCreated User.userDecoder
        }

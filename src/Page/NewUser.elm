module Page.NewUser exposing (..)

{-
   https://elmprogramming.com/creating-a-new-post.html
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
    , newUser : Maybe User.User
    , createError : Maybe String
    }


initNU : Nav.Key -> ( ModelNU, Cmd MsgNU )
initNU navKey =
    ( initialModelNU navKey, Cmd.none )


initialModelNU : Nav.Key -> ModelNU
initialModelNU navKeyParam =
    { navKey = navKeyParam
    , newUser = Nothing
    , createError = Nothing
    }


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
            , input [ type_ "text", onInput UpdateName ] []
            ]
        , br [] []
        , div []
            [ text "Email"
            , br [] []
            , input [ type_ "text", onInput UpdateEmail ] []
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
    = UpdateName String
    | UpdateEmail String
    | CreateNewUser
    | NewUserCreated (Result Http.Error User.User)


updateNU : MsgNU -> ModelNU -> ( ModelNU, Cmd MsgNU )
updateNU msg model =
    case msg of
        UpdateName newName ->
            let
                oldUserData =
                    Maybe.withDefault User.emptyUser model.newUser

                updatedUser =
                    { oldUserData | name = User.UserName newName }
            in
            ( { model | newUser = Just updatedUser }, Cmd.none )

        UpdateEmail newEmail ->
            let
                oldUserData =
                    Maybe.withDefault User.emptyUser model.newUser

                updatedUser =
                    { oldUserData | email = User.UserEmail newEmail }
            in
            ( { model | newUser = Just updatedUser }, Cmd.none )

        CreateNewUser ->
            ( model, createNewUser (Maybe.withDefault User.emptyUser model.newUser) )

        NewUserCreated (Ok serverResponse) ->
            ( { model | newUser = Just serverResponse, createError = Nothing }
            , Route.pushUrl Route.LandingPageRoute model.navKey
            )

        NewUserCreated (Err error) ->
            ( { model | newUser = Nothing, createError = Just (EM.buildErrorMessage error) }
            , Cmd.none
            )



-- createNewUser : User.User -> Cmd MsgNU
-- createNewUser newUser =
--     Http.post
--         { url = "http://localhost:5019/users"
--         , body = Http.jsonBody (User.newUserEncoder newUser)
--         , expect = Http.expectJson NewUserCreated User.userDecoder
--         }
{-
   curl -v \
   -H "Content-Type: application/json" \
   --request POST \
   --data '{"name": "sam", "email": "email5@email.com", "password": "DuqOT2024!"}' \
   https://teemingtooth.backendless.app/api/data/people

-}


createNewUser : User.User -> Cmd MsgNU
createNewUser newUser =
    Http.post
        { url = "https://teemingtooth.backendless.app/api/data/people"
        , body = Http.jsonBody (User.newUserEncoder newUser)
        , expect = Http.expectJson NewUserCreated User.userDecoder
        }

module Page.EditUser exposing (..)

{-
   https://elmprogramming.com/editing-a-post.html
-}

import Browser.Navigation as Nav
import Challenge
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
    , challenges : RD.WebData (List Challenge.Challenge)
    , saveError : Maybe String
    }


initialModelEU : Nav.Key -> ModelEU
initialModelEU navKeyParam =
    { navKey = navKeyParam
    , user = RD.Loading
    , challenges = RD.Loading
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


fetchChallenges : Cmd MsgEU
fetchChallenges =
    Http.get
        { url = "http://localhost:5019/challenges"
        , expect =
            Challenge.listOfChallengesDecoder
                |> Http.expectJson (RD.fromResult >> ChallengesReceived)
        }


type MsgEU
    = UserReceived (RD.WebData User.User)
    | ChallengesReceived (RD.WebData (List Challenge.Challenge))
    | UpdateUserName String
    | ToggleChallenge Challenge.ChallengeId
    | SaveUser
      -- UserSaved payload doesn’t need to be of type WebData because we aren’t interested
      -- in tracking all the states our PATCH request goes through
    | UserSaved (Result Http.Error User.User)


updateEU : MsgEU -> ModelEU -> ( ModelEU, Cmd MsgEU )
updateEU msg model =
    case msg of
        -- Get the user's record from the server
        UserReceived serverResponse ->
            ( { model | user = serverResponse }
            , fetchChallenges
            )

        -- Get the list of all the challenges from the server
        ChallengesReceived responseFromServer ->
            ( { model | challenges = responseFromServer }
            , Cmd.none
            )

        -- User changed the name in the input box
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

        -- User toggled the completion button for a task
        ToggleChallenge challengeId ->
            case model.user of
                RD.Success userData ->
                    ( { model | user = RD.Success (toggleChallenge userData challengeId) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        -- User presses the update button
        SaveUser ->
            ( model, saveUser model.user )

        -- Update worked
        UserSaved (Ok userData) ->
            let
                savedUser =
                    RD.succeed userData
            in
            ( { model | user = savedUser, saveError = Nothing }
            , Route.pushUrl Route.LandingPageRoute model.navKey
            )

        -- Update didn't work
        UserSaved (Err error) ->
            ( { model | saveError = Just (EM.buildErrorMessage error) }
            , Cmd.none
            )


toggleChallenge : User.User -> Challenge.ChallengeId -> User.User
toggleChallenge user challengeId =
    if List.member challengeId user.completedChallenges then
        { user | completedChallenges = List.filter (\x -> x /= challengeId) user.completedChallenges }

    else
        { user | completedChallenges = challengeId :: user.completedChallenges }


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
        , viewUser model.user model.challenges
        , viewSaveError model.saveError
        ]


viewUser : RD.WebData User.User -> RD.WebData (List Challenge.Challenge) -> Html MsgEU
viewUser user challenges =
    case user of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading User Data..." ]

        RD.Success userData ->
            editUserForm userData challenges

        RD.Failure httpError ->
            viewFetchError (EM.buildErrorMessage httpError)


editUserForm : User.User -> RD.WebData (List Challenge.Challenge) -> Html MsgEU
editUserForm user challenges =
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
        , viewListOfChallenges user.completedChallenges challenges
        , br [] []
        , div []
            [ button [ type_ "button", onClick SaveUser ]
                [ text "Update User Information" ]
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


viewListOfChallenges : List Challenge.ChallengeId -> RD.WebData (List Challenge.Challenge) -> Html MsgEU
viewListOfChallenges completedChallenges challenges =
    case challenges of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading..." ]

        RD.Success listOfChallenges ->
            div []
                [ h3 [] [ text "Gratitude Challenges" ]
                , div []
                    (List.map (viewChallenge completedChallenges) listOfChallenges)
                ]

        RD.Failure httpError ->
            viewFetchChallengesError (EM.buildErrorMessage httpError)


viewChallenge : List Challenge.ChallengeId -> Challenge.Challenge -> Html MsgEU
viewChallenge completedChallenges challenge =
    let
        checkboxName =
            Challenge.challengeIdToString challenge.id

        completed =
            List.member challenge.id completedChallenges
    in
    div []
        [ input
            [ type_ "checkbox"
            , onClick (ToggleChallenge challenge.id)
            , checked completed
            , name checkboxName
            ]
            []
        , label [ for checkboxName ]
            [ text (Challenge.challengeTitleToString challenge.title) ]
        ]


viewFetchChallengesError : String -> Html MsgEU
viewFetchChallengesError errorMessage =
    let
        errorHeading =
            "Couldn't fetch challenges at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]

module Page.DisplayChallenge exposing (..)

{-
   https://elmprogramming.com/editing-a-post.html
-}

import Browser.Navigation as Nav
import Challenge
import ErrorMessages as EM
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import RemoteData as RD
import Route
import User


type alias ModelDC =
    { navKey : Nav.Key
    , challenge : RD.WebData Challenge.Challenge
    , userId : User.UserId
    , user : RD.WebData User.User
    , saveError : Maybe String
    }


initDC : Maybe User.User -> Challenge.ChallengeId -> Nav.Key -> ( ModelDC, Cmd MsgDC )
initDC user challengeId navKey =
    case user of
        Nothing ->
            ( initialModelDC User.emptyUserId navKey, fetchChallenge challengeId )

        Just u ->
            ( initialModelDC u.id navKey, fetchChallenge challengeId )


initialModelDC : User.UserId -> Nav.Key -> ModelDC
initialModelDC userIdParam navKeyParam =
    { navKey = navKeyParam
    , challenge = RD.Loading
    , userId = userIdParam
    , user = RD.Loading
    , saveError = Nothing
    }


fetchUser : User.UserId -> Cmd MsgDC
fetchUser userId =
    Http.get
        { url = "http://localhost:5019/users/" ++ User.userIdToString userId
        , expect =
            User.userDecoder
                -- func1 >> func2 == \param -> func2 (fun1 param)
                -- RD.fromResult >> UserReceived = \p -> UserReceived (RD.fromResult p)
                |> Http.expectJson (RD.fromResult >> UserReceived)
        }


fetchChallenge : Challenge.ChallengeId -> Cmd MsgDC
fetchChallenge challengeId =
    Http.get
        { url = "http://localhost:5019/challenges/" ++ Challenge.challengeIdToString challengeId
        , expect =
            Challenge.challengeDecoder
                |> Http.expectJson (RD.fromResult >> ChallengeReceived)
        }


type MsgDC
    = ChallengeReceived (RD.WebData Challenge.Challenge)
    | UserReceived (RD.WebData User.User)
    | ToggleChallenge Challenge.ChallengeId
    | SaveUser
      -- UserSaved payload doesn’t need to be of type WebData because we aren’t interested
      -- in tracking all the states our PATCH request goes through
    | UserSaved (Result Http.Error User.User)


updateDC : MsgDC -> ModelDC -> ( ModelDC, Cmd MsgDC )
updateDC msg model =
    case msg of
        -- Get this week's challenge
        ChallengeReceived serverResponse ->
            ( { model | challenge = serverResponse }, fetchUser model.userId )

        -- Get the user's record from the server
        UserReceived serverResponse ->
            ( { model | user = serverResponse }
            , Cmd.none
            )

        -- User toggled the completion button for a task
        ToggleChallenge challengeId ->
            case model.user of
                RD.Success userData ->
                    ( { model | user = RD.succeed (toggleChallenge userData challengeId) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        -- -- User pressed the save challenge button
        -- SaveChallenge ->
        --     ( model, saveChallenge model.challenge )
        -- ChallengeSaved (Ok serverResponse) ->
        --     let
        --         challengeData =
        --             RD.succeed serverResponse
        --     in
        --     ( { model | challenge = challengeData, saveError = Nothing }
        --     , Cmd.none
        --     )
        -- ChallengeSaved (Err error) ->
        --     ( { model | saveError = Just (EM.buildErrorMessage error) }
        --     , Cmd.none
        --     )
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


saveUser : RD.WebData User.User -> Cmd MsgDC
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


viewDC : ModelDC -> Html MsgDC
viewDC model =
    div []
        [ h3 [] [ text "This Week's Challenge" ]
        , viewChallenge model.challenge model.user
        , EM.viewSaveError model.saveError
        ]


viewChallenge : RD.WebData Challenge.Challenge -> RD.WebData User.User -> Html MsgDC
viewChallenge challenge user =
    case challenge of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading Challenge..." ]

        RD.Success challengeData ->
            displayChallengeForm challengeData user

        RD.Failure httpError ->
            viewFetchError (EM.buildErrorMessage httpError)


displayChallengeForm : Challenge.Challenge -> RD.WebData User.User -> Html MsgDC
displayChallengeForm challenge user =
    Html.form []
        [ div []
            [ h3 [] [ text "Title" ]
            , text (Challenge.challengeTitleToString challenge.title)
            , br [] []
            , h3 [] [ text "Description" ]
            , text (Challenge.challengeDescriptionToString challenge.description)
            , br [] []
            ]
        , br [] []
        , displayCompletionCheckbox challenge user
        , br [] []
        ]


displayCompletionCheckbox : Challenge.Challenge -> RD.WebData User.User -> Html MsgDC
displayCompletionCheckbox challenge user =
    case user of
        RD.Success u ->
            let
                completed =
                    List.member challenge.id u.completedChallenges
            in
            div []
                [ input
                    [ type_ "checkbox"
                    , checked completed
                    , onClick (ToggleChallenge challenge.id)
                    , name "myCB"
                    ]
                    []
                , label [ for "myCB" ]
                    [ text "Challenge Completed" ]
                , br [] []
                , div []
                    [ button [ type_ "button", onClick SaveUser ]
                        [ text "Update" ]
                    ]
                ]

        _ ->
            div [] []


viewFetchError : String -> Html MsgDC
viewFetchError errorMessage =
    let
        errorHeading =
            "Couldn't fetch post at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]

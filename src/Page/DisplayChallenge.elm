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

    -- The response I get from the server is a list with one JSON object in it
    -- I need to write code to get the one ojbect out
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



-- fetchUser : User.UserId -> Cmd MsgDC
-- fetchUser userId =
--     Http.get
--         { url = "http://localhost:5019/users/" ++ User.userIdToString userId
--         , expect =
--             User.userDecoder
--                 -- func1 >> func2 == \param -> func2 (fun1 param)
--                 -- RD.fromResult >> UserReceived = \p -> UserReceived (RD.fromResult p)
--                 |> Http.expectJson (RD.fromResult >> UserReceived)
--         }
-- When this works, I get back a list with one user. I get back a list because I'm asking for
-- "all the entries with id=<x>" where <x> is the user id.


fetchUser : User.UserId -> Cmd MsgDC
fetchUser userId =
    Http.get
        { url =
            "https://teemingtooth.backendless.app/api/data/people?where=id%3D" ++ User.userIdToString userId
        , expect =
            User.listOfUsersDecoder
                -- func1 >> func2 == \param -> func2 (fun1 param)
                -- RD.fromResult >> UserReceived = \p -> UserReceived (RD.fromResult p)
                |> Http.expectJson (RD.fromResult >> UserReceived)
        }



-- fetchUsers : Cmd MsgLI
-- fetchUsers =
--     Http.get
--         { url = "https://teemingtooth.backendless.app/api/data/people"
--         , expect =
--             User.listOfUsersDecoder
--                 |> Http.expectJson (RD.fromResult >> UsersReceived)
--         }
-- When this works, I get back a list with one challenge. I get back a list because I'm asking for
-- "all the entries with id=<x>" where <x> is the challenge id.


fetchChallenge : Challenge.ChallengeId -> Cmd MsgDC
fetchChallenge challengeId =
    Http.get
        { url = "https://teemingtooth.backendless.app/api/data/challenges?where=id%3D" ++ Challenge.challengeIdToString challengeId
        , expect =
            Challenge.listOfChallengesDecoder
                |> Http.expectJson (RD.fromResult >> ChallengeReceived)
        }



-- fetchChallenges : Cmd MsgLoC
-- fetchChallenges =
--     Http.get
--         { url = "https://teemingtooth.backendless.app/api/data/challenges?props=id,title,description"
--         , expect =
--             Challenge.listOfChallengesDecoder
--                 |> Http.expectJson (RD.fromResult >> ChallengesReceived)
--         }


type MsgDC
    = ChallengeReceived (RD.WebData (List Challenge.Challenge))
    | UserReceived (RD.WebData (List User.User))
    | ToggleChallenge Challenge.ChallengeId
    | SaveUser
      -- UserSaved payload doesn’t need to be of type WebData because we aren’t interested
      -- in tracking all the states our PATCH request goes through
    | UserSaved (Result Http.Error User.User)


extractChallenge : RD.WebData (List Challenge.Challenge) -> RD.WebData Challenge.Challenge
extractChallenge responseFromServer =
    case responseFromServer of
        RD.NotAsked ->
            RD.NotAsked

        RD.Loading ->
            RD.Loading

        RD.Success (firstChallenge :: otherChallenges) ->
            RD.Success firstChallenge

        RD.Success _ ->
            RD.Failure (Http.BadBody "1")

        RD.Failure e ->
            RD.Failure e


extractUser : RD.WebData (List User.User) -> RD.WebData User.User
extractUser responseFromServer =
    case responseFromServer of
        RD.NotAsked ->
            RD.NotAsked

        RD.Loading ->
            RD.Loading

        RD.Success (firstUser :: otherUsers) ->
            RD.Success firstUser

        RD.Success _ ->
            RD.Failure (Http.BadBody "1")

        RD.Failure e ->
            RD.Failure e


updateDC : MsgDC -> ModelDC -> ( ModelDC, Cmd MsgDC )
updateDC msg model =
    case msg of
        -- Get this week's challenge
        ChallengeReceived serverResponse ->
            ( { model | challenge = extractChallenge serverResponse }, fetchUser model.userId )

        -- Get the user's record from the server
        UserReceived serverResponse ->
            ( { model | user = extractUser serverResponse }
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



-- saveUser : RD.WebData User.User -> Cmd MsgDC
-- saveUser user =
--     case user of
--         RD.Success newUser ->
--             Http.post
--                 { url = "https://teemingtooth.backendless.app/api/data/people"
--                 , body = Http.jsonBody (User.newUserEncoder newUser)
--                 , expect = Http.expectJson UserSaved User.userDecoder
--                 }
--         _ ->
--             Cmd.none


saveUser : RD.WebData User.User -> Cmd MsgDC
saveUser user =
    case user of
        RD.Success newUser ->
            Http.request
                (Debug.log
                    "Save user request"
                    { method = "PUT"
                    , headers = []
                    , url = "https://teemingtooth.backendless.app/api/data/people/" ++ newUser.objectId
                    , body = Http.jsonBody (User.newUserEncoder newUser)
                    , expect = Http.expectJson UserSaved User.userDecoder
                    , timeout = Nothing
                    , tracker = Nothing
                    }
                )

        _ ->
            Cmd.none



{-
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
-}


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

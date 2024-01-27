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
    , thisWeeksChallenge : Int
    , saveError : Maybe String
    }


initialModelEU : Int -> Nav.Key -> ModelEU
initialModelEU thisWeek navKeyParam =
    { navKey = navKeyParam
    , user = RD.Loading
    , challenges = RD.Loading
    , thisWeeksChallenge = thisWeek
    , saveError = Nothing
    }


initEU : User.UserId -> Int -> Nav.Key -> ( ModelEU, Cmd MsgEU )
initEU userId thisWeek navKey =
    ( initialModelEU thisWeek navKey, fetchUser userId )



-- fetchUser : User.UserId -> Cmd MsgEU
-- fetchUser userId =
--     Http.get
--         { url = "http://localhost:5019/users/" ++ User.userIdToString userId
--         , expect =
--             User.userDecoder
--                 -- func1 >> func2 == \param -> func2 (fun1 param)
--                 -- RD.fromResult >> UserReceived = \p -> UserReceived (RD.fromResult p)
--                 |> Http.expectJson (RD.fromResult >> UserReceived)
--         }
{-
   curl "https://teemingtooth.backendless.app/api/data/people/first?props=id,completedChallenges,name,password,objectId&where=id&3D1"
-}
-- When this works, I get back a list with one user. I get back a list because I'm asking for
-- "all the entries with id=<x>" where <x> is the user id.


fetchUser : User.UserId -> Cmd MsgEU
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



-- fetchChallenges : Cmd MsgEU
-- fetchChallenges =
--     Http.get
--         { url = "http://localhost:5019/challenges"
--         , expect =
--             Challenge.listOfChallengesDecoder
--                 |> Http.expectJson (RD.fromResult >> ChallengesReceived)
--         }


fetchChallenges : Cmd MsgEU
fetchChallenges =
    Http.get
        { url = "https://teemingtooth.backendless.app/api/data/challenges"
        , expect =
            Challenge.listOfChallengesDecoder
                |> Http.expectJson (RD.fromResult >> ChallengesReceived)
        }


type MsgEU
    = UserReceived (RD.WebData (List User.User))
    | ChallengesReceived (RD.WebData (List Challenge.Challenge))
    | UpdateUserName String
    | ToggleChallenge Challenge.ChallengeId
    | SaveUser
      -- UserSaved payload doesn’t need to be of type WebData because we aren’t interested
      -- in tracking all the states our PATCH request goes through
    | UserSaved (Result Http.Error User.User)


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


updateEU : MsgEU -> ModelEU -> ( ModelEU, Cmd MsgEU )
updateEU msg model =
    case msg of
        -- Get the user's record from the server
        UserReceived serverResponse ->
            ( { model | user = extractUser serverResponse }
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



{-
   createNewUser : User.User -> Cmd MsgNU
   createNewUser newUser =
       Http.post
           { url = "https://teemingtooth.backendless.app/api/data/people"
           , body = Http.jsonBody (User.newUserEncoder newUser)
           , expect = Http.expectJson NewUserCreated User.userDecoder
           }

-}
-- saveUser : RD.WebData User.User -> Cmd MsgEU
-- saveUser user =
--     case user of
--         RD.Success newUser ->
--             Http.post
--                 { url = "https://teemingtooth.backendless.app/api/data/people/" ++ newUser.objectId
--                 , body = Http.jsonBody (User.newUserEncoder newUser)
--                 , expect = Http.expectJson UserSaved User.userDecoder
--                 }
--         _ ->
--             Cmd.none
{-
   curl -v \
   -H "Content-Type: application/json" \
   --request PUT \
   --data '{"name": "sam"}' \
   https://teemingtooth.backendless.app/api/data/people/3FC0C9BF-5BDC-4BE2-8C83-F5F879AC8392

-}


saveUser : RD.WebData User.User -> Cmd MsgEU
saveUser user =
    case user of
        RD.Success newUser ->
            Http.request
                (Debug.log
                    "Save user request"
                    { method = "PUT"

                    -- , headers = [ Http.header "Content-Type" "application/json" ]
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
-}


viewEU : ModelEU -> Html MsgEU
viewEU model =
    div []
        [ h3 [] [ text "User Information" ]
        , viewUser model
        , viewSaveError model.saveError
        ]


viewUser : ModelEU -> Html MsgEU
viewUser model =
    case model.user of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading User Data..." ]

        RD.Success userData ->
            editUserForm userData model.thisWeeksChallenge model.challenges

        RD.Failure httpError ->
            viewFetchUserError (EM.buildErrorMessage httpError)


editUserForm : User.User -> Int -> RD.WebData (List Challenge.Challenge) -> Html MsgEU
editUserForm user thisWeeksChallenge challenges =
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
        , viewListOfChallenges user.completedChallenges thisWeeksChallenge challenges
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


viewFetchUserError : String -> Html MsgEU
viewFetchUserError errorMessage =
    let
        errorHeading =
            "Couldn't fetch user at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]


viewListOfChallenges : List Challenge.ChallengeId -> Int -> RD.WebData (List Challenge.Challenge) -> Html MsgEU
viewListOfChallenges completedChallenges thisWeeksChallenge challenges =
    case challenges of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading..." ]

        RD.Success listOfChallenges ->
            let
                shortenedListOfChallenges =
                    List.sortBy Challenge.challengeIdAsInt listOfChallenges
                        |> List.take thisWeeksChallenge
            in
            div []
                [ h3 [] [ text "Gratitude Challenges" ]
                , div []
                    (List.map (viewChallenge completedChallenges) shortenedListOfChallenges)
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

module Page.ListOfChallenges exposing (..)

{-
   elm install elm/http
   elm install krisajenkins/remotedata
-}
--import Json.Decode as Decode

import Challenge
import ErrorMessages as EM
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events
import Http
import RemoteData as RD



{-
   https://elmprogramming.com/creating-list-posts-page.html
-}


type alias ModelLoC =
    { challenges : RD.WebData (List Challenge.Challenge)
    , thisWeeksChallenge : Int
    }


initModelLoC : Int -> ModelLoC
initModelLoC theWeek =
    { challenges = RD.Loading
    , thisWeeksChallenge = theWeek
    }


type MsgLoC
    = FetchChallenges
    | ChallengesReceived (RD.WebData (List Challenge.Challenge))


initLoC : Int -> ( ModelLoC, Cmd MsgLoC )
initLoC theWeek =
    ( initModelLoC theWeek
    , fetchChallenges
    )



-- fetchChallenges : Cmd MsgLoC
-- fetchChallenges =
--     Http.get
--         { url = "http://localhost:5019/challenges"
--         , expect =
--             Challenge.listOfChallengesDecoder
--                 |> Http.expectJson (RD.fromResult >> ChallengesReceived)
--         }
{-
   curl "https://teemingtooth.backendless.app/api/data/challenges?props=title,description"
-}


fetchChallenges : Cmd MsgLoC
fetchChallenges =
    Http.get
        { url = "https://teemingtooth.backendless.app/api/data/challenges"
        , expect =
            Challenge.listOfChallengesDecoder
                |> Http.expectJson (RD.fromResult >> ChallengesReceived)
        }


updateLoC : MsgLoC -> ModelLoC -> ( ModelLoC, Cmd MsgLoC )
updateLoC msg model =
    case msg of
        FetchChallenges ->
            ( { model | challenges = RD.Loading }
            , fetchChallenges
            )

        ChallengesReceived responseFromServer ->
            ( { model | challenges = responseFromServer }
            , Cmd.none
            )


viewLoC : ModelLoC -> Html MsgLoC
viewLoC model =
    div []
        [ button [ Events.onClick FetchChallenges ]
            [ text "Refresh Challenges" ]
        , viewListOfChallenges model
        ]


viewListOfChallenges : ModelLoC -> Html MsgLoC
viewListOfChallenges model =
    case model.challenges of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading..." ]

        RD.Success listOfChallenges ->
            let
                shortenedListOfChallenges =
                    List.sortBy Challenge.challengeIdAsInt listOfChallenges
                        |> List.take model.thisWeeksChallenge
            in
            div []
                [ h3 [] [ text "Gratitude Challenges" ]
                , table []
                    (viewTableHeader :: List.map viewChallenge shortenedListOfChallenges)
                ]

        RD.Failure httpError ->
            viewFetchError (EM.buildErrorMessage httpError)


viewChallenge : Challenge.Challenge -> Html MsgLoC
viewChallenge challenge =
    let
        challengePath =
            "/challenges/" ++ Challenge.challengeIdToString challenge.id
    in
    tr []
        [ td []
            [ text (Challenge.challengeIdToString challenge.id) ]
        , td []
            [ text (Challenge.challengeTitleToString challenge.title) ]
        , td []
            [ text (Challenge.challengeDescriptionToString challenge.description) ]
        , td []
            [ a [ href challengePath ] [ text "Display" ] ]
        ]


viewTableHeader : Html MsgLoC
viewTableHeader =
    tr []
        [ th []
            [ text "ID" ]
        , th []
            [ text "Title" ]
        , th []
            [ text "Description" ]
        ]


viewFetchError : String -> Html MsgLoC
viewFetchError errorMessage =
    let
        errorHeading =
            "Couldn't fetch challenges at this time."
    in
    div []
        [ h3 [] [ text errorHeading ]
        , text ("Error: " ++ errorMessage)
        ]

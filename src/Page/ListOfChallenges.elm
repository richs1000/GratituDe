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
    }


initModelLoC : ModelLoC
initModelLoC =
    { challenges = RD.Loading
    }


type MsgLoC
    = FetchChallenges
    | ChallengesReceived (RD.WebData (List Challenge.Challenge))


initLoC : ( ModelLoC, Cmd MsgLoC )
initLoC =
    ( initModelLoC
    , fetchChallenges
    )


fetchChallenges : Cmd MsgLoC
fetchChallenges =
    Http.get
        { url = "http://localhost:5019/challenges"
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
        , viewListOfChallenges model.challenges
        ]


viewListOfChallenges : RD.WebData (List Challenge.Challenge) -> Html MsgLoC
viewListOfChallenges challenges =
    case challenges of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading..." ]

        RD.Success listOfChallenges ->
            div []
                [ h3 [] [ text "Gratitude Challenges" ]
                , table []
                    (viewTableHeader :: List.map viewChallenge listOfChallenges)
                ]

        RD.Failure httpError ->
            viewFetchError (EM.buildErrorMessage httpError)


viewChallenge : Challenge.Challenge -> Html MsgLoC
viewChallenge challenge =
    tr []
        [ td []
            [ text (Challenge.challengeIdToString challenge.id) ]
        , td []
            [ text (Challenge.challengeTitleToString challenge.title) ]
        , td []
            [ text (Challenge.challengeDescriptionToString challenge.description) ]
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


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message

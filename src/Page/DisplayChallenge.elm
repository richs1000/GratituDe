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


type alias ModelDC =
    { navKey : Nav.Key
    , challenge : RD.WebData Challenge.Challenge
    , saveError : Maybe String
    }


initDC : Challenge.ChallengeId -> Nav.Key -> ( ModelDC, Cmd MsgDC )
initDC challengeId navKey =
    ( initialModelDC navKey, fetchChallenge challengeId )


initialModelDC : Nav.Key -> ModelDC
initialModelDC navKeyParam =
    { navKey = navKeyParam
    , challenge = RD.Loading
    , saveError = Nothing
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
    | SaveChallenge
    | ChallengeSaved (Result Http.Error Challenge.Challenge)


updateDC : MsgDC -> ModelDC -> ( ModelDC, Cmd MsgDC )
updateDC msg model =
    case msg of
        ChallengeReceived serverResponse ->
            ( { model | challenge = serverResponse }, Cmd.none )

        SaveChallenge ->
            ( model, saveChallenge model.challenge )

        ChallengeSaved (Ok serverResponse) ->
            let
                challengeData =
                    RD.succeed serverResponse
            in
            ( { model | challenge = challengeData, saveError = Nothing }
            , Cmd.none
            )

        ChallengeSaved (Err error) ->
            ( { model | saveError = Just (EM.buildErrorMessage error) }
            , Cmd.none
            )


saveChallenge : RD.WebData Challenge.Challenge -> Cmd MsgDC
saveChallenge challenge =
    case challenge of
        RD.Success challengeData ->
            let
                challengeUrl =
                    "http://localhost:5019/challenges/"
                        ++ Challenge.challengeIdToString challengeData.id
            in
            Http.request
                { method = "PATCH"
                , headers = []
                , url = challengeUrl
                , body = Http.jsonBody (Challenge.challengeEncoder challengeData)
                , expect = Http.expectJson ChallengeSaved Challenge.challengeDecoder
                , timeout = Nothing
                , tracker = Nothing
                }

        _ ->
            Cmd.none


viewDC : ModelDC -> Html MsgDC
viewDC model =
    div []
        [ h3 [] [ text "This Week's Challenge" ]
        , viewChallenge model.challenge
        , EM.viewSaveError model.saveError
        ]


viewChallenge : RD.WebData Challenge.Challenge -> Html MsgDC
viewChallenge challenge =
    case challenge of
        RD.NotAsked ->
            text ""

        RD.Loading ->
            h3 [] [ text "Loading Challenge..." ]

        RD.Success challengeData ->
            displayChallengeForm challengeData

        RD.Failure httpError ->
            viewFetchError (EM.buildErrorMessage httpError)


displayChallengeForm : Challenge.Challenge -> Html MsgDC
displayChallengeForm challenge =
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
        , div []
            [ input
                [ type_ "checkbox"
                , checked True
                , name "myCB"
                ]
                []
            , label [ for "myCB" ]
                [ text "Challenge Completed" ]
            ]
        , br [] []
        , div []
            [ button [ type_ "button", onClick SaveChallenge ]
                [ text "Submit" ]
            ]
        , br [] []
        ]


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

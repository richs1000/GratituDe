module Challenge exposing (..)

{-
   elm install elm/json
   elm install NoRedInk/elm-json-decode-pipeline
-}

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline



{-
   https://elmprogramming.com/creating-post-module.html
-}


type alias Challenge =
    { id : ChallengeId
    , title : ChallengeTitle
    , description : ChallengeDescription
    }


type ChallengeId
    = ChallengeId Int


challengeIdDecoder : Decode.Decoder ChallengeId
challengeIdDecoder =
    Decode.map ChallengeId Decode.int


challengeIdToString : ChallengeId -> String
challengeIdToString (ChallengeId idAsInt) =
    String.fromInt idAsInt


type ChallengeTitle
    = ChallengeTitle String


challengeTitleDecoder : Decode.Decoder ChallengeTitle
challengeTitleDecoder =
    Decode.map ChallengeTitle Decode.string


challengeTitleToString : ChallengeTitle -> String
challengeTitleToString (ChallengeTitle titleAsString) =
    titleAsString


type ChallengeDescription
    = ChallengeDescription String


challengeDescriptionDecoder : Decode.Decoder ChallengeDescription
challengeDescriptionDecoder =
    Decode.map ChallengeDescription Decode.string


challengeDescriptionToString : ChallengeDescription -> String
challengeDescriptionToString (ChallengeDescription descriptionAsString) =
    descriptionAsString


type ChallengeCompleted
    = ChallengeCompleted Bool


challengeCompletedDecoder : Decode.Decoder ChallengeCompleted
challengeCompletedDecoder =
    Decode.map ChallengeCompleted Decode.bool


challengeCompletedToString : ChallengeCompleted -> String
challengeCompletedToString (ChallengeCompleted completedAsBool) =
    if completedAsBool then
        "Completed"

    else
        "Not Completed"


listOfChallengesDecoder : Decode.Decoder (List Challenge)
listOfChallengesDecoder =
    Decode.list challengeDecoder


challengeDecoder : Decode.Decoder Challenge
challengeDecoder =
    Decode.succeed Challenge
        |> Pipeline.required "id" challengeIdDecoder
        |> Pipeline.required "title" challengeTitleDecoder
        |> Pipeline.required "description" challengeDescriptionDecoder

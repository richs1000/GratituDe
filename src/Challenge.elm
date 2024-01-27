module Challenge exposing (..)

{-
   elm install elm/json
   elm install NoRedInk/elm-json-decode-pipeline
-}

import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Url.Parser



{-
   https://elmprogramming.com/creating-post-module.html
-}


type alias Challenge =
    { id : ChallengeId
    , title : ChallengeTitle
    , description : ChallengeDescription
    }


challengeEncoder : Challenge -> Encode.Value
challengeEncoder challenge =
    Encode.object
        [ ( "id", challengeIdEncoder challenge.id )
        , ( "title", challengeTitleEncoder challenge.title )
        , ( "authorName", challengeDescriptionEncoder challenge.description )
        ]


challengeDecoder : Decode.Decoder Challenge
challengeDecoder =
    Decode.succeed Challenge
        |> Pipeline.required "id" challengeIdDecoder
        |> Pipeline.required "title" challengeTitleDecoder
        |> Pipeline.required "description" challengeDescriptionDecoder


listOfChallengesDecoder : Decode.Decoder (List Challenge)
listOfChallengesDecoder =
    Decode.list challengeDecoder


type ChallengeId
    = ChallengeId Int


challengeIdDecoder : Decode.Decoder ChallengeId
challengeIdDecoder =
    Decode.map ChallengeId Decode.int


challengeIdEncoder : ChallengeId -> Encode.Value
challengeIdEncoder (ChallengeId id) =
    Encode.int id


challengeIdToString : ChallengeId -> String
challengeIdToString (ChallengeId idAsInt) =
    String.fromInt idAsInt


challengeIdAsInt : Challenge -> Int
challengeIdAsInt challenge =
    case challenge.id of
        ChallengeId idAsInt ->
            idAsInt



-- Extracts a challenge ID from a URL


challengeIdParser : Url.Parser.Parser (ChallengeId -> a) a
challengeIdParser =
    Url.Parser.custom "CHALLENGEID" <|
        \challengeIdAsString ->
            Maybe.map ChallengeId (String.toInt challengeIdAsString)


type ChallengeTitle
    = ChallengeTitle String


challengeTitleDecoder : Decode.Decoder ChallengeTitle
challengeTitleDecoder =
    Decode.map ChallengeTitle Decode.string


challengeTitleEncoder : ChallengeTitle -> Encode.Value
challengeTitleEncoder (ChallengeTitle title) =
    Encode.string title


challengeTitleToString : ChallengeTitle -> String
challengeTitleToString (ChallengeTitle titleAsString) =
    titleAsString


type ChallengeDescription
    = ChallengeDescription String


challengeDescriptionDecoder : Decode.Decoder ChallengeDescription
challengeDescriptionDecoder =
    Decode.map ChallengeDescription Decode.string


challengeDescriptionEncoder : ChallengeDescription -> Encode.Value
challengeDescriptionEncoder (ChallengeDescription description) =
    Encode.string description


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

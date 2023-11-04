module User exposing (..)

{-
   elm install elm/json
   elm install NoRedInk/elm-json-decode-pipeline
-}

import Challenge
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline



{-
   https://elmprogramming.com/creating-post-module.html
-}


type alias User =
    { id : UserId
    , name : UserName
    , completedChallenges : List Challenge.ChallengeId
    }


type UserId
    = UserId Int


userIdDecoder : Decode.Decoder UserId
userIdDecoder =
    Decode.map UserId Decode.int


userIdToString : UserId -> String
userIdToString (UserId idAsInt) =
    String.fromInt idAsInt


type UserName
    = UserName String


userNameDecoder : Decode.Decoder UserName
userNameDecoder =
    Decode.map UserName Decode.string


userNameToString : UserName -> String
userNameToString (UserName titleAsString) =
    titleAsString


completedChallengesDecoder : Decode.Decoder (List Challenge.ChallengeId)
completedChallengesDecoder =
    Decode.list Challenge.challengeIdDecoder


completedChallengesToString : List Challenge.ChallengeId -> String
completedChallengesToString listOfChallengeIds =
    -- convert list of challenge IDs to a list of strings
    List.map Challenge.challengeIdToString listOfChallengeIds
        -- convert list of strings to a single comma-separated string
        |> String.join ", "


listOfUsersDecoder : Decode.Decoder (List User)
listOfUsersDecoder =
    Decode.list userDecoder


userDecoder : Decode.Decoder User
userDecoder =
    Decode.succeed User
        |> Pipeline.required "id" userIdDecoder
        |> Pipeline.required "name" userNameDecoder
        |> Pipeline.required "completedChallenges" completedChallengesDecoder

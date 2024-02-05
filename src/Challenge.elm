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



-- Find the longest streak of completed challenges
-- [5, 4, 3, 2, 1] -> 5
-- [5, 3, 2, 1] -> 3
-- [5, 3, 1] -> 1
-- [5, 4, 2, 1] -> 2
-- [6, 5, 4, 2, 1] -> 3


longestStreak : List ChallengeId -> Int
longestStreak challenges =
    let
        longestStreakHelper : Int -> Int -> List ChallengeId -> Int
        longestStreakHelper streakCount maxStreak remainingChallenges =
            case remainingChallenges of
                [] ->
                    -- We're at the end of the list of challenges, return the longest streak
                    -- found in the list
                    Basics.max 0 maxStreak

                c :: [] ->
                    -- There is one item left in the list, add one to the current streak count
                    -- Compare the current streak count to the longest streak count found
                    -- Return whichever is bigger
                    Basics.max (streakCount + 1) maxStreak

                c1 :: c2 :: cs ->
                    if getIdAsInt c1 == (getIdAsInt c2 + 1) then
                        -- The first and second challenge IDs in the list are consecutive
                        -- Add one to the current streak count
                        -- Update the longest streak count if the current streak count is longest
                        -- Move on to the rest of the list (c2 :: cs)
                        longestStreakHelper (streakCount + 1) (Basics.max (streakCount + 1) maxStreak) (c2 :: cs)

                    else
                        -- The first and second challenge IDs in the list are not consecutive
                        -- Restart the current streak count at zero
                        -- Update the longest streak count if the streak that just ended was longer
                        -- Move on to the rest of the list (cs :: cs)
                        longestStreakHelper 0 (Basics.max (streakCount + 1) maxStreak) (c2 :: cs)
    in
    longestStreakHelper 0 0 challenges



-- Does the user have an active streak? If the user has already completed the current week's challenge
-- or has completed the previous week's challenge, then they have an active streak. This function
-- counts how many challenges in a row have been completed.
-- If this week is week #6:
-- [5, 4, 3, 2, 1] -> 5
-- [5, 3, 2, 1] -> 1
-- [5, 3, 1] -> 1
-- [5, 4, 2, 1] -> 2
-- [6, 5, 4, 2, 1] -> 3


activeStreak : List ChallengeId -> Int -> Int
activeStreak challenges thisWeek =
    let
        activeStreakHelper : Int -> List ChallengeId -> Int
        activeStreakHelper streakCount remainingChallenges =
            case remainingChallenges of
                [] ->
                    -- There are no remaining items, so return the length of the streak
                    streakCount

                c :: [] ->
                    -- There is one item left in the list, add one to the current streak count
                    -- Return the updated streak count
                    streakCount + 1

                c1 :: c2 :: cs ->
                    if getIdAsInt c1 == (getIdAsInt c2 + 1) then
                        -- The first and second challenge IDs in the list are consecutive
                        -- Add one to the current streak count
                        -- Move on to the rest of the list (c2 :: cs)
                        activeStreakHelper (streakCount + 1) (c2 :: cs)

                    else
                        -- The streak ended, return the streak count
                        streakCount + 1
    in
    case challenges of
        [] ->
            0

        c :: cs ->
            if (getIdAsInt c == thisWeek) || (getIdAsInt c == thisWeek - 1) then
                activeStreakHelper 0 (c :: cs)

            else
                0



-- Convert a ChallengeId type to a regular Int so I can use it for sorting


getIdAsInt : ChallengeId -> Int
getIdAsInt (ChallengeId idAsInt) =
    idAsInt

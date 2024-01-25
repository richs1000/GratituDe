module User exposing (..)

{-
   elm install elm/json
   elm install NoRedInk/elm-json-decode-pipeline
-}

import Challenge
import Html exposing (a)
import Json.Decode as Decode
import Json.Decode.Pipeline as Pipeline
import Json.Encode as Encode
import Url.Parser



{-
   https://elmprogramming.com/creating-post-module.html
-}
{-
   This is the definition for the User record. All the stuff below is for accessing, encoding,
   decoding and parsing this record.
-}


type alias User =
    { id : UserId
    , name : UserName
    , email : UserEmail
    , password : UserPassword
    , completedChallenges : List Challenge.ChallengeId
    , objectId : String
    }


emptyUser : User
emptyUser =
    { id = emptyUserId
    , name = emptyUserName
    , email = emptyUserEmail
    , password = emptyUserPassword
    , completedChallenges = emptyCompletedChallenges
    , objectId = ""
    }


userDecoder : Decode.Decoder User
userDecoder =
    Decode.succeed User
        |> Pipeline.required "id" userIdDecoder
        |> Pipeline.required "name" userNameDecoder
        |> Pipeline.required "email" userEmailDecoder
        |> Pipeline.required "password" userPasswordDecoder
        |> Pipeline.required "completedChallenges" completedChallengesDecoder
        |> Pipeline.required "objectId" Decode.string


listOfUsersDecoder : Decode.Decoder (List User)
listOfUsersDecoder =
    Decode.list userDecoder


userEncoder : User -> Encode.Value
userEncoder user =
    Encode.object
        [ ( "id", userIdEncoder user.id )
        , ( "name", userNameEncoder user.name )
        , ( "email", userEmailEncoder user.email )
        , ( "password", userPasswordEncoder user.password )
        , ( "completedChallenges", completedChallengesEncoder user.completedChallenges )
        , ( "objectId", Encode.string user.objectId )
        ]


newUserEncoder : User -> Encode.Value
newUserEncoder user =
    Encode.object
        [ ( "name", userNameEncoder user.name )
        , ( "email", userEmailEncoder user.email )
        , ( "password", userPasswordEncoder user.password )
        , ( "completedChallenges", completedChallengesEncoder user.completedChallenges )
        ]



{-
   The UserId is a unique identifier for each user. To ask the JSON database for a specific
   user, use "/users/<id>"
-}


type UserId
    = UserId Int


emptyUserId : UserId
emptyUserId =
    UserId -1


userIdDecoder : Decode.Decoder UserId
userIdDecoder =
    Decode.map UserId Decode.int


userIdEncoder : UserId -> Encode.Value
userIdEncoder (UserId id) =
    Encode.int id


userIdToString : UserId -> String
userIdToString (UserId idAsInt) =
    String.fromInt idAsInt



-- Extracts a user ID from a URL


userIdParser : Url.Parser.Parser (UserId -> a) a
userIdParser =
    Url.Parser.custom "USERID" <|
        \userIdAsString ->
            Maybe.map UserId (String.toInt userIdAsString)



{-
   The name of the user. At some point, maybe we get fancy and support
   separate first and last names...
-}


type UserName
    = UserName String


emptyUserName : UserName
emptyUserName =
    UserName ""


userNameDecoder : Decode.Decoder UserName
userNameDecoder =
    Decode.map UserName Decode.string


userNameEncoder : UserName -> Encode.Value
userNameEncoder (UserName name) =
    Encode.string name


userNameToString : UserName -> String
userNameToString (UserName nameAsString) =
    nameAsString



{-
   The email of the user.
-}


type UserEmail
    = UserEmail String


emptyUserEmail : UserEmail
emptyUserEmail =
    UserEmail ""


userEmailDecoder : Decode.Decoder UserEmail
userEmailDecoder =
    Decode.map UserEmail Decode.string


userEmailEncoder : UserEmail -> Encode.Value
userEmailEncoder (UserEmail email) =
    Encode.string email


userEmailToString : UserEmail -> String
userEmailToString (UserEmail emailAsString) =
    emailAsString



{-
   The password of the user.
-}


type UserPassword
    = UserPassword String


emptyUserPassword : UserPassword
emptyUserPassword =
    UserPassword "DuqOT2024!"


userPasswordDecoder : Decode.Decoder UserPassword
userPasswordDecoder =
    Decode.map UserPassword Decode.string


userPasswordEncoder : UserPassword -> Encode.Value
userPasswordEncoder (UserPassword password) =
    Encode.string password


userPasswordToString : UserPassword -> String
userPasswordToString (UserPassword passwordAsString) =
    passwordAsString



{-
   Each user has completed 0 or more challenges. We store a list of
   ChallengeIds (from the Challenge module) to reflect the challenges
   that have been completed.
-}


emptyCompletedChallenges : List Challenge.ChallengeId
emptyCompletedChallenges =
    []


completedChallengesDecoder : Decode.Decoder (List Challenge.ChallengeId)
completedChallengesDecoder =
    Decode.list Challenge.challengeIdDecoder


completedChallengesEncoder : List Challenge.ChallengeId -> Encode.Value
completedChallengesEncoder =
    Encode.list Challenge.challengeIdEncoder


completedChallengesToString : List Challenge.ChallengeId -> String
completedChallengesToString listOfChallengeIds =
    -- convert list of challenge IDs to a list of strings
    List.map Challenge.challengeIdToString listOfChallengeIds
        -- convert list of strings to a single comma-separated string
        |> String.join ", "

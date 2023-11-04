module Route exposing (..)

{-
   https://elmprogramming.com/navigating-to-list-posts-page.html
-}
{-
   elm install elm/url
-}

import Url
import Url.Parser


type Route
    = NotFound
    | ListOfChallenges
    | ListOfUsers


parseUrl : Url.Url -> Route
parseUrl url =
    case Url.Parser.parse routeParsers url of
        Just route ->
            route

        Nothing ->
            NotFound


routeParsers : Url.Parser.Parser (Route -> a) a
routeParsers =
    Url.Parser.oneOf
        [ Url.Parser.map ListOfUsers Url.Parser.top
        , Url.Parser.map ListOfUsers (Url.Parser.s "users")
        , Url.Parser.map ListOfChallenges (Url.Parser.s "challenges")
        ]

module Route exposing (..)

{-
   https://elmprogramming.com/navigating-to-list-posts-page.html
   https://elmprogramming.com/editing-a-post.html
-}
{-
   elm install elm/url
-}

import Url
import Url.Parser exposing ((</>))
import User


type Route
    = RouteNotFound
    | ListOfChallengesRoute
    | ListOfUsersRoute
    | UserRoute User.UserId


parseUrl : Url.Url -> Route
parseUrl url =
    case Url.Parser.parse routeParsers url of
        Just route ->
            route

        Nothing ->
            RouteNotFound


routeParsers : Url.Parser.Parser (Route -> a) a
routeParsers =
    Url.Parser.oneOf
        [ Url.Parser.map ListOfUsersRoute Url.Parser.top
        , Url.Parser.map ListOfUsersRoute (Url.Parser.s "users")
        , Url.Parser.map ListOfChallengesRoute (Url.Parser.s "challenges")
        , Url.Parser.map UserRoute (Url.Parser.s "users" </> User.userIdParser)
        ]

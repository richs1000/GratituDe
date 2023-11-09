module Route exposing (..)

{-
   https://elmprogramming.com/navigating-to-list-posts-page.html
   https://elmprogramming.com/editing-a-post.html
   https://elmprogramming.com/creating-a-new-post.html
-}
{-
   elm install elm/url
-}

import Browser.Navigation as Nav
import Challenge
import Url
import Url.Parser exposing ((</>))
import User


type Route
    = RouteNotFound
    | LandingPageRoute
    | ListOfChallengesRoute
    | ListOfUsersRoute
    | UserRoute User.UserId
    | ChallengeRoute Challenge.ChallengeId
    | NewUserRoute


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
        [ Url.Parser.map LandingPageRoute Url.Parser.top
        , Url.Parser.map LandingPageRoute (Url.Parser.s "home")
        , Url.Parser.map ListOfUsersRoute (Url.Parser.s "users")
        , Url.Parser.map ListOfChallengesRoute (Url.Parser.s "challenges")
        , Url.Parser.map UserRoute (Url.Parser.s "users" </> User.userIdParser)
        , Url.Parser.map ChallengeRoute (Url.Parser.s "challenges" </> Challenge.challengeIdParser)
        , Url.Parser.map NewUserRoute (Url.Parser.s "users" </> Url.Parser.s "new")
        ]


pushUrl : Route -> Nav.Key -> Cmd msg
pushUrl route navKey =
    routeToString route
        |> Nav.pushUrl navKey


routeToString : Route -> String
routeToString route =
    case route of
        RouteNotFound ->
            "/not-found"

        ListOfChallengesRoute ->
            "/challenges"

        ListOfUsersRoute ->
            "/users"

        UserRoute userId ->
            "/users/" ++ User.userIdToString userId

        ChallengeRoute challengeId ->
            "/challenges/" ++ Challenge.challengeIdToString challengeId

        NewUserRoute ->
            "/users/new"

        LandingPageRoute ->
            "/"

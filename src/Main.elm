module Main exposing (main)

{-
   https://elmprogramming.com/navigating-to-list-posts-page.html
   https://livebook.manning.com/book/elm-in-action/chapter-8/50
   https://elmprogramming.com/creating-a-new-post.html

   https://github.com/justinmimbs/date
-}
{-
   json-server --watch server/gratitude.json -p 5019 --delay 2000
   elm-live src/Main.elm --pushstate -- --debug

   git add .
   git commit -m "
   git push -u github main
-}
{-
   elm install justinmimbs/date
-}

import Browser
import Browser.Navigation as Nav
import Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.DisplayChallenge as DC
import Page.EditUser as EU
import Page.ListOfChallenges as LoC
import Page.ListOfUsers as LoU
import Page.NewUser as NU
import Route
import Task
import Url


type alias Model =
    -- current route (from URL)
    { route : Route.Route

    -- current page
    , currentPage : Page

    -- navKey is used internally by Elm for accessing the browser's
    -- address bar
    , navKey : Nav.Key

    -- I need to know what week of the year it is (1-52) so I can
    -- display the correct challenge of the week
    , thisWeeksChallenge : Int
    }


type Page
    = NotFoundPage
    | LandingPage
    | ListOfUsersPage LoU.ModelLoU
    | ListOfChallengesPage LoC.ModelLoC
    | EditUserPage EU.ModelEU
    | DisplayChallengePage DC.ModelDC
    | NewUserPage NU.ModelNU


type
    Msg
    -- holds messages from List of Users page
    = LoUPageMsg LoU.MsgLoU
      -- holds messages from List of Challenges page
    | LoCPageMsg LoC.MsgLoC
      -- holds message from Edit User page
    | EUPageMsg EU.MsgEU
      -- holds message from Display Challenge page
    | DCPageMsg DC.MsgDC
      -- holds message from New User page
    | NUPageMsg NU.MsgNU
      -- user clicked on a link
    | LinkClicked Browser.UrlRequest
      -- URL in browser changes
    | UrlChanged Url.Url
      -- when we start, we need to get the current date
    | ReceiveDate Date.Date


initMain : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
initMain flags url navKey =
    let
        model =
            { route = Route.parseUrl url
            , currentPage = NotFoundPage
            , navKey = navKey
            , thisWeeksChallenge = 0
            }
    in
    setCurrentPage
        ( model
        , Date.today |> Task.perform ReceiveDate
        )


setCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
setCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            -- look at the route we parsed from the URL
            case model.route of
                -- if the route didn't parse to an existing page...
                Route.RouteNotFound ->
                    -- go to the "not found" page
                    ( NotFoundPage, Cmd.none )

                Route.LandingPageRoute ->
                    -- display the "home" page
                    ( LandingPage, Cmd.none )

                -- if the route parsed to our list of users page...
                Route.ListOfUsersRoute ->
                    let
                        -- use the init function for the List Of Users page to get
                        -- the listOfUsers.model
                        -- the commands generated by initializing the LoU page
                        ( modelForLoU, commandsFromLoU ) =
                            LoU.initLoU
                    in
                    -- currentPage =
                    ( ListOfUsersPage modelForLoU
                      -- mappedPageCmds =
                    , Cmd.map LoUPageMsg commandsFromLoU
                    )

                -- if the route parsed to our list of challenges page...
                Route.ListOfChallengesRoute ->
                    let
                        -- use the init function for the List Of Challenges page to get
                        -- the listOfChallenges.model
                        -- the commands generated by initializing the LoC page
                        ( modelForLoC, commandsFromLoC ) =
                            LoC.initLoC
                    in
                    -- currentPage =
                    ( ListOfChallengesPage modelForLoC
                      -- mappedPageCmds =
                    , Cmd.map LoCPageMsg commandsFromLoC
                    )

                -- if the route parsed to a specific user's page
                Route.UserRoute userId ->
                    let
                        -- use the init function for the Edit User page to get
                        -- the editUser.model
                        -- the commands generated by initializing the EU page
                        ( modelForEU, commandsFromEU ) =
                            EU.initEU userId model.navKey
                    in
                    -- currentPage =
                    ( EditUserPage modelForEU
                      -- mappedPageCmds =
                    , Cmd.map EUPageMsg commandsFromEU
                    )

                -- if the route parsed to display a specific challenge
                Route.ChallengeRoute challengeId ->
                    let
                        -- use the init function for the Display Challenge page
                        -- to get the displayChallenge.model
                        -- the commands generated by initializing the DC page
                        ( modelForDC, commandsFromDC ) =
                            DC.initDC challengeId model.navKey
                    in
                    -- currentPage =
                    ( DisplayChallengePage modelForDC
                      -- mappedPageCmds =
                    , Cmd.map DCPageMsg commandsFromDC
                    )

                -- if the route parsed to add a new user page
                Route.NewUserRoute ->
                    let
                        -- use the init function for the New User page
                        -- to get the newUser.model
                        -- the commands generated by initializing the NU page
                        ( modelForNU, commandsFromNU ) =
                            NU.initNU model.navKey
                    in
                    -- currentPage =
                    ( NewUserPage modelForNU
                      -- mappedPageCmds =
                    , Cmd.map NUPageMsg commandsFromNU
                    )
    in
    -- update model with current page based on route
    ( { model | currentPage = currentPage }
      -- add the commands from LoC or LoU to existing commands
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )


viewMain : Model -> Browser.Document Msg
viewMain model =
    { title = "GratituDUe"
    , body =
        [ headerView model
        , currentView model
        , footerView
        ]
    }


footerView : Html Msg
footerView =
    footer []
        [ br [] []
        , br [] []
        , text "Copyright and other footer stuff..."
        ]


headerView : Model -> Html Msg
headerView model =
    let
        logo =
            a [ href "/home" ]
                [ h1 [] [ text "GratituDe" ] ]

        lineBreaks =
            div []
                [ br [] []
                , br [] []
                ]

        links =
            ul []
                [ li [] [ a [ href "/home" ] [ text "Home" ] ]
                , li [] [ a [ href ("/challenges/" ++ String.fromInt model.thisWeeksChallenge) ] [ text "This Week's Challenge" ] ]
                , li [] [ a [ href "/enhanceYou" ] [ text "Enhance You" ] ]
                , li [] [ a [ href "/sota" ] [ text "SOTA" ] ]
                , li [] [ a [ href "/login" ] [ text "Login" ] ]
                ]
    in
    nav []
        [ logo
        , links
        , lineBreaks
        ]


currentView : Model -> Html Msg
currentView model =
    case model.currentPage of
        NotFoundPage ->
            notFoundView

        LandingPage ->
            landingPageView

        ListOfUsersPage modelLoU ->
            LoU.viewLoU modelLoU
                |> Html.map LoUPageMsg

        ListOfChallengesPage modelLoC ->
            LoC.viewLoC modelLoC
                |> Html.map LoCPageMsg

        EditUserPage modelEU ->
            EU.viewEU modelEU
                |> Html.map EUPageMsg

        DisplayChallengePage modelDC ->
            DC.viewDC modelDC
                |> Html.map DCPageMsg

        NewUserPage modelNU ->
            NU.viewNU modelNU
                |> Html.map NUPageMsg


notFoundView : Html Msg
notFoundView =
    h3 [] [ text "Oops! The page you requested was not found!" ]


landingPageView : Html Msg
landingPageView =
    let
        duqLogo =
            div []
                [ text "Duquesne University Logo"
                , br [] []
                , br [] []
                ]

        appLogo =
            div []
                [ text "GratituDe Logo"
                , br [] []
                , br [] []
                ]

        appMotto =
            div []
                [ text "Get in tune with your mind, body and soul"
                , br [] []
                , br [] []
                ]
    in
    div []
        [ duqLogo
        , appLogo
        , appMotto
        ]


updateMain : Msg -> Model -> ( Model, Cmd Msg )
updateMain msg model =
    case ( msg, model.currentPage ) of
        ( LoUPageMsg msgLoU, ListOfUsersPage modelLoU ) ->
            let
                -- use the List of Users update function to get new model and command
                ( updatedLoUModel, updatedLoUCmd ) =
                    LoU.updateLoU msgLoU modelLoU
            in
            -- update current page to have the new model
            ( { model | currentPage = ListOfUsersPage updatedLoUModel }
              -- update the current command to be the command from the LoU init function
            , Cmd.map LoUPageMsg updatedLoUCmd
            )

        ( LoCPageMsg msgLoC, ListOfChallengesPage modelLoC ) ->
            let
                -- use the List of Challenges update function to get new model and command
                ( updatedLoCModel, updatedLoCCmd ) =
                    LoC.updateLoC msgLoC modelLoC
            in
            -- update current page to have the new model
            ( { model | currentPage = ListOfChallengesPage updatedLoCModel }
              -- update the current command to be the command from the LoU init function
            , Cmd.map LoCPageMsg updatedLoCCmd
            )

        ( EUPageMsg msgEU, EditUserPage modelEU ) ->
            let
                -- use the Edit User update function to get new model and command
                ( updatedEUModel, updatedEUCmd ) =
                    EU.updateEU msgEU modelEU
            in
            -- update current page to have the new model
            ( { model | currentPage = EditUserPage updatedEUModel }
              -- update the current command to be the command from the EU init function
            , Cmd.map EUPageMsg updatedEUCmd
            )

        ( DCPageMsg msgDC, DisplayChallengePage modelDC ) ->
            let
                -- use the Display Challenge update function to get new model and command
                ( updatedDCModel, updatedDCCmd ) =
                    DC.updateDC msgDC modelDC
            in
            -- update current page to have the new model
            ( { model | currentPage = DisplayChallengePage updatedDCModel }
              -- update the current command to be the command from the DC init function
            , Cmd.map DCPageMsg updatedDCCmd
            )

        ( NUPageMsg msgNU, NewUserPage modelNU ) ->
            let
                -- use the New User update function to get new model and command
                ( updatedNUModel, updatedNUCmd ) =
                    NU.updateNU msgNU modelNU
            in
            -- update current page to have the new model
            ( { model | currentPage = NewUserPage updatedNUModel }
              -- update the current command to be the command from the NU init function
            , Cmd.map NUPageMsg updatedNUCmd
            )

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> setCurrentPage

        ( ReceiveDate theDate, _ ) ->
            let
                -- The "ordinal day" (1-366) divided by 7 gives
                -- me the "ordinal week" (1-52), this lets me know
                -- what challenge to display
                oWeek =
                    (Date.ordinalDay theDate // 7) + 1
            in
            ( { model | thisWeeksChallenge = oWeek }
            , Cmd.none
            )

        ( _, _ ) ->
            ( model, Cmd.none )


main : Program () Model Msg
main =
    Browser.application
        { init = initMain
        , view = viewMain
        , update = updateMain
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }

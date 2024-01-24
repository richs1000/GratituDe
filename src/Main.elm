module Main exposing (main)

{-
   https://elmprogramming.com/navigating-to-list-posts-page.html
   https://livebook.manning.com/book/elm-in-action/chapter-8/50
   https://elmprogramming.com/creating-a-new-post.html

   css:
   https://elmprogramming.com/model-view-update-part-2.html
   elm install rtfeldman/elm-css
   elm install elm/virtual-dom

   https://github.com/justinmimbs/date

-}
{-
   elm init

   json-server --watch server/gratitude.json -p 5019

   http-server-spa: https://livebook.manning.com/book/elm-in-action/chapter-8/175
   http-server-spa .

   elm make src/Main.elm --output app.js --debug

   git branch <branch name>
   git checkout <branch name>
   git add .
   git commit -m "
   git checkout main
   git merge <branch name>
   git push -u github main
   git branch -d <branch name>

    debug.log : https://livebook.manning.com/book/elm-in-action/chapter-8/133
    debug.todo: https://livebook.manning.com/book/elm-in-action/chapter-8/192

-}
{-
   elm install justinmimbs/date
-}
-- import Page.ListOfUsers as LoU

import Browser
import Browser.Navigation as Nav
import Date
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.DisplayChallenge as DC
import Page.EditUser as EU
import Page.EnhanceYou as EY
import Page.ListOfChallenges as LoC
import Page.LogIn as LI
import Page.NewUser as NU
import RemoteData as RD
import Route
import Task
import Url
import User


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

    -- this stores the information about the user who is logged in
    -- If a user is not logged in, then user = Nothing
    , user : Maybe User.User
    }


type Page
    = NotFoundPage
    | LandingPage
      -- | ListOfUsersPage LoU.ModelLoU
    | ListOfChallengesPage LoC.ModelLoC
    | EditUserPage EU.ModelEU
    | DisplayChallengePage DC.ModelDC
    | NewUserPage NU.ModelNU
    | LogInPage LI.ModelLI
    | EnhanceYouPage


type
    Msg
    -- holds message from Edit User page
    = EUPageMsg EU.MsgEU
      -- holds message from Display Challenge page
    | DCPageMsg DC.MsgDC
      -- holds message from New User page
    | NUPageMsg NU.MsgNU
      -- holds message from Log In page
    | LIPageMsg LI.MsgLI
      -- user clicked on a link
    | LinkClicked Browser.UrlRequest
      -- URL in browser changes
    | UrlChanged Url.Url
      -- when we start, we need to get the current date
    | ReceiveDate Date.Date
      -- holds messages from List of Users page
      -- | LoUPageMsg LoU.MsgLoU
      -- holds messages from List of Challenges page
    | LoCPageMsg LoC.MsgLoC


initMain : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
initMain flags url navKey =
    let
        model =
            { route = Route.parseUrl url
            , currentPage = NotFoundPage
            , navKey = navKey
            , thisWeeksChallenge = 0
            , user = Nothing
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

                {-
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
                -}
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
                            DC.initDC model.user challengeId model.navKey
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

                -- if the route parsed to add a new user page
                Route.LogInRoute ->
                    let
                        -- use the init function for the Log In page
                        -- to get the logIn.model
                        -- the commands generated by initializing the LI page
                        ( modelForLI, commandsFromLI ) =
                            LI.initLI model.navKey
                    in
                    -- currentPage =
                    ( LogInPage modelForLI
                      -- mappedPageCmds =
                    , Cmd.map LIPageMsg commandsFromLI
                    )

                -- if the route parsed to the "Enhance You" page
                Route.EnhanceYouRoute ->
                    -- currentPage =
                    ( EnhanceYouPage
                      -- mappedPageCmds =
                    , Cmd.none
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
        , br [] []
        , a [ href "/challenges" ] [ text "Challenges" ]
        ]



{-
   https://livebook.manning.com/book/elm-in-action/chapter-8/50
   https://livebook.manning.com/book/elm-in-action/chapter-8/89
-}


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

        user =
            Maybe.withDefault User.emptyUser model.user

        userPath =
            "/users/" ++ User.userIdToString user.id

        links =
            if user.id == User.emptyUserId then
                ul []
                    [ li [] [ a [ href "/home" ] [ text "Home" ] ]
                    , li [] [ a [ href ("/challenges/" ++ String.fromInt model.thisWeeksChallenge) ] [ text "This Week's Challenge" ] ]
                    , li [] [ a [ href "/enhanceyou" ] [ text "Enhance You" ] ]

                    -- , li [] [ a [ href "/sota" ] [ text "SOTA" ] ]
                    , li [] [ a [ href "/login" ] [ text "Log In" ] ]
                    , li [] [ a [ href "/users/new" ] [ text "New User" ] ]
                    ]

            else
                ul []
                    [ li [] [ a [ href "/home" ] [ text "Home" ] ]
                    , li [] [ a [ href ("/challenges/" ++ String.fromInt model.thisWeeksChallenge) ] [ text "This Week's Challenge" ] ]
                    , li [] [ a [ href "/enhanceyou" ] [ text "Enhance You" ] ]

                    -- , li [] [ a [ href "/sota" ] [ text "SOTA" ] ]
                    , li [] [ a [ href userPath ] [ text (User.userNameToString user.name) ] ]
                    , li [] [ a [ href "/login" ] [ text "Log Out" ] ]
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

        -- ListOfUsersPage modelLoU ->
        --     LoU.viewLoU modelLoU
        --         |> Html.map LoUPageMsg
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

        EnhanceYouPage ->
            -- enhanceYouView
            EY.viewEY

        LogInPage modelLI ->
            LI.viewLI modelLI
                |> Html.map LIPageMsg


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
        {-
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
        -}
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
            -- If we got an updated user back from Edit User, then update the
            -- model with that new user. Otherwise, just move on...
            case updatedEUModel.user of
                RD.Success newUser ->
                    ( { model
                        | currentPage = EditUserPage updatedEUModel
                        , user = Just newUser
                      }
                      -- update the current command to be the command from the EU init function
                    , Cmd.map EUPageMsg updatedEUCmd
                    )

                _ ->
                    ( { model
                        | currentPage = EditUserPage updatedEUModel
                      }
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
            -- update current page to have the new model
            -- If we got an updated user back from Edit User, then update the
            -- model with that new user. Otherwise, just move on...
            case updatedDCModel.user of
                RD.Success newUser ->
                    ( { model
                        | currentPage = DisplayChallengePage updatedDCModel
                        , user = Just newUser
                      }
                      -- update the current command to be the command from the DC init function
                    , Cmd.map DCPageMsg updatedDCCmd
                    )

                _ ->
                    ( { model | currentPage = DisplayChallengePage updatedDCModel }
                    , Cmd.map DCPageMsg updatedDCCmd
                    )

        ( NUPageMsg msgNU, NewUserPage modelNU ) ->
            let
                -- use the New User update function to get new model and command
                ( updatedNUModel, updatedNUCmd ) =
                    NU.updateNU msgNU modelNU
            in
            -- update current page to have the new model
            ( { model
                | currentPage = NewUserPage updatedNUModel
                , user = updatedNUModel.newUser
              }
              -- update the current command to be the command from the NU init function
            , Cmd.map NUPageMsg updatedNUCmd
            )

        ( LIPageMsg msgLI, LogInPage modelLI ) ->
            let
                -- use the Log In update function to get new model and command
                ( updatedLIModel, updatedLICmd ) =
                    LI.updateLI msgLI modelLI
            in
            -- update current page to have the new model
            -- update the user in the current model based on the user who just logged in
            ( { model
                | currentPage = LogInPage (Debug.log "In updateMain, LIModel = " updatedLIModel)
                , user = updatedLIModel.newUser
              }
              -- update the current command to be the command from the LI init function
            , Cmd.map LIPageMsg updatedLICmd
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

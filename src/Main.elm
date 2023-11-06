module Main exposing (main)

{-
   https://elmprogramming.com/navigating-to-list-posts-page.html
   https://livebook.manning.com/book/elm-in-action/chapter-8/50
-}
{-
   json-server --watch server/gratitude.json -p 5019 --delay 2000
   elm-live src/Main.elm --pushstate -- --debug
-}

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Page.EditUser as EU
import Page.ListOfChallenges as LoC
import Page.ListOfUsers as LoU
import Route
import Url


type alias Model =
    -- current route (from URL)
    { route : Route.Route

    -- current page
    , currentPage : Page
    , navKey : Nav.Key
    }


type Page
    = NotFoundPage
    | ListOfUsersPage LoU.ModelLoU
    | ListOfChallengesPage LoC.ModelLoC
    | EditUserPage EU.ModelEU


type
    Msg
    -- holds messages from List of Users page
    = LoUPageMsg LoU.MsgLoU
      -- holds messages from List of Challenges page
    | LoCPageMsg LoC.MsgLoC
      -- holds message from Edit User page
    | EUPageMsg EU.MsgEU
      -- user clicked on a link
    | LinkClicked Browser.UrlRequest
      -- URL in browser changes
    | UrlChanged Url.Url


initMain : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
initMain flags url navKey =
    let
        model =
            { route = Route.parseUrl url
            , currentPage = NotFoundPage
            , navKey = navKey
            }
    in
    setCurrentPage ( model, Cmd.none )


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
        [ text "Copyright and other footer stuff..." ]


headerView : Model -> Html Msg
headerView model =
    let
        logo =
            h1 [] [ text "GratituDe" ]

        links =
            ul []
                [ li [] [ a [ href "#" ] [ text "Link 1" ] ]
                , li [] [ a [ href "#" ] [ text "Link 2" ] ]
                ]
    in
    nav [] [ logo, links ]


currentView : Model -> Html Msg
currentView model =
    case model.currentPage of
        NotFoundPage ->
            notFoundView

        ListOfUsersPage modelLoU ->
            LoU.viewLoU modelLoU
                |> Html.map LoUPageMsg

        ListOfChallengesPage modelLoC ->
            LoC.viewLoC modelLoC
                |> Html.map LoCPageMsg

        EditUserPage modelEU ->
            EU.viewEU modelEU
                |> Html.map EUPageMsg


notFoundView : Html msg
notFoundView =
    h3 [] [ text "Oops! The page you requested was not found!" ]


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

module Main exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Navigation exposing (Location)


type Msg
    = SetPage Location
    | ToggleNavbar
    | SortBy SortOption
    | MakeSquigg
    | Update InputField String
    | ToggleSignInForm


type InputField
    = DraftSquigg
    | Username
    | Password


type SortOption
    = Top
    | Recent
    | Awful


type alias User =
    { id : String
    }


type alias Votes =
    { up : Int
    }


type alias Squigg =
    { content : String
    , user : User
    , votes : Votes
    }


type alias Context =
    { user : Maybe User
    , squiggs : List Squigg
    }


type alias Model =
    { context : Context
    , expandedNavbar : Bool
    , sortOption : SortOption
    , sortAscending : Bool
    , draft : String
    , squiggs : List Squigg
    , username : String
    , password : String
    , showSignInForm : Bool
    }


main : Program Context Model Msg
main =
    Navigation.programWithFlags
        SetPage
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : Context -> Location -> ( Model, Cmd Msg )
init context location =
    Model
        context
        False
        Top
        True
        ""
        []
        ""
        ""
        True
        ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPage location ->
            model ! []

        ToggleNavbar ->
            { model | expandedNavbar = not model.expandedNavbar } ! []

        SortBy sortOption ->
            if sortOption == model.sortOption then
                { model | sortAscending = not model.sortAscending } ! []
            else
                { model | sortOption = sortOption } ! []

        MakeSquigg ->
            case model.context.user of
                Just user ->
                    makeSquigg (Squigg model.draft user (Votes 0)) model ! []

                Nothing ->
                    model ! []

        Update DraftSquigg draft ->
            { model | draft = draft } ! []

        Update Username username ->
            { model | username = username } ! []

        Update Password password ->
            { model | password = password } ! []

        ToggleSignInForm ->
            { model | showSignInForm = not model.showSignInForm } ! []


makeSquigg : Squigg -> Model -> Model
makeSquigg squigg model =
    { model
        | draft = ""
        , squiggs = model.squiggs ++ [ squigg ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


baroot : Html Msg
baroot =
    span []
        [ text "ba"
        , em [] [ text "root" ]
        , text "?"
        ]


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ viewNavbar model.draft ( model.sortOption, model.sortAscending ) model.expandedNavbar model.context.user
        , viewPage model.context
        , viewSignInModal model model.showSignInForm
        ]


navbarTabs : List SortOption
navbarTabs =
    [ Top, Recent, Awful ]


type alias SortInfo =
    ( SortOption, Bool )


viewNavbar : String -> SortInfo -> Bool -> Maybe User -> Html Msg
viewNavbar draft sortInfo expandedNavbar user =
    nav [ class "navbar has-shadow" ]
        [ div [ class "navbar-brand" ]
            [ a [ class "navbar-item", href "/" ]
                [ img [ src "/penguin.png", alt "baroot penguino" ] []
                , h3 [ class "subtitle is-padded-left" ] [ baroot ]
                ]
            , div
                [ class "navbar-burger"
                , classList [ ( "is-active", expandedNavbar ) ]
                , onClick ToggleNavbar
                ]
                [ span [] []
                , span [] []
                , span [] []
                ]
            ]
        , div [ class "navbar-menu", classList [ ( "is-active", expandedNavbar ) ] ]
            [ div [ class "navbar-start" ]
                [ div [ class "nav-item tabs is-toggle is-marginless" ]
                    [ ul [] (List.map (viewNavbarTab sortInfo) navbarTabs)
                    ]
                , if user /= Nothing then
                    viewNewPostField draft
                  else
                    text ""
                ]
            , div [ class "navbar-end" ]
                [ div [ class "nav-item" ]
                    (if user == Nothing then
                        [ button
                            [ class "button is-info is-outlined"
                            , onClick ToggleSignInForm
                            ]
                            [ text "Sign in" ]
                        ]
                     else
                        [ button [ class "button is-link is-outlined" ] [ text "Sign out" ] ]
                    )
                ]
            ]
        ]


isValidPost : String -> Bool
isValidPost value_ =
    String.length value_ > 0


viewNewPostField : String -> Html Msg
viewNewPostField value_ =
    div [ class "nav-item field has-addons" ]
        [ div [ class "control" ]
            [ input
                [ class "input"
                , type_ "text"
                , onInput (Update DraftSquigg)
                , placeholder "Make a squigg"
                , value value_
                ]
                []
            ]
        , div [ class "control" ]
            [ if isValidPost value_ then
                button [ class "button is-info", onClick MakeSquigg ] [ text "Send" ]
              else
                button [ class "button", disabled True ] [ text "Send" ]
            ]
        ]


viewNavbarTab : SortInfo -> SortOption -> Html Msg
viewNavbarTab ( activeOption, ascending ) option =
    let
        isActive =
            activeOption == option
    in
    li
        [ classList [ ( "is-active", isActive ) ] ]
        [ a [ onClick (SortBy option) ]
            (if isActive then
                [ span [ class "icon is-small" ]
                    [ i
                        [ class "fa"
                        , classList
                            [ ( "fa-sort-amount-asc", ascending )
                            , ( "fa-sort-amount-desc", not ascending )
                            ]
                        ]
                        []
                    ]
                , span [] [ text (toString option) ]
                ]
             else
                [ text (toString option) ]
            )
        ]


viewPage : Context -> Html Msg
viewPage context =
    div [ class "hero" ] []


type alias SignInForm a =
    { a | username : String, password : String }


viewSignInModal : SignInForm a -> Bool -> Html Msg
viewSignInModal formInputs showForm =
    div [ class "modal", classList [ ( "is-active", showForm ) ] ]
        [ div
            [ class "modal-background"
            , onClick ToggleSignInForm
            ]
            []
        , div [ class "modal-content" ]
            [ viewSignInForm formInputs
            ]
        , div
            [ class "modal-close is-large"
            , attribute "aria-label" "close"
            , onClick ToggleSignInForm
            ]
            []
        ]


viewSignInForm : SignInForm a -> Html Msg
viewSignInForm { username, password } =
    div [ class "box" ]
        [ viewFormInput "text" "Username" (Update Username) username
        , viewFormInput "password" "Password" (Update Password) password
        , hr [] []
        , if isValidSignInForm username password then
            button [ class "button is-info" ] [ text "Sign in" ]
          else
            button [ class "button is-info", disabled True ] [ text "Sign in" ]
        ]


viewFormInput : String -> String -> (String -> Msg) -> String -> Html Msg
viewFormInput inputType label_ msg value_ =
    div [ class "field" ]
        [ label [ class "label" ] [ text label_ ]
        , div [ class "control" ]
            [ input
                [ class "input"
                , type_ inputType
                , onInput msg
                , value value_
                ]
                []
            ]
        ]


isValidSignInForm : String -> String -> Bool
isValidSignInForm username password =
    String.length username > 0 && String.length password > 0

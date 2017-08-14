module Main exposing (main)

import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Navigation exposing (Location)


type Msg
    = SetPage Location
    | ToggleNavbar
    | SortBy SortOption
    | MakeSquigg
    | MakeSquiggRespond (Result Http.Error (ApiResponse Squigg))
    | Update InputField String
    | ToggleSignInForm
    | SignInClicked
    | SignUpClicked
    | SignOutClicked
    | SignInRespond (Result Http.Error (ApiResponse User))
    | SignOutRespond (Result Http.Error (ApiResponse String))


type InputField
    = DraftSquigg
    | Username
    | Password


type SortOption
    = Top
    | Recent
    | Awful


type alias Credentials a =
    { a
        | username : String
        , password : String
    }


type alias SigningInStatus a =
    { a
        | showSignInForm : Bool
        , signingUp : Bool
        , signingIn : Bool
        , signInError : String
    }


type alias ApiResponse a =
    { error : Bool
    , message : String
    , data : List a
    }


type alias Id =
    String


type alias User =
    { id : Id
    }


type alias Votes =
    { up : Int
    }


type alias Squigg =
    { id : Id
    , content : String
    , user : Id
    , timestamp : String
    , votes : List Id
    }


type alias Context =
    { user : Maybe User
    , squiggs : List Squigg
    }


type Page
    = Homepage


type alias Model =
    { user : Maybe User
    , squiggs : List Squigg
    , page : Page
    , expandedNavbar : Bool
    , sortOption : SortOption
    , sortAscending : Bool
    , draft : String
    , username : String
    , password : String
    , showSignInForm : Bool
    , signingUp : Bool
    , signingIn : Bool
    , signInError : String
    , creatingSquigg : Bool
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
        context.user
        context.squiggs
        (getPageFrom location)
        False
        Top
        False
        ""
        ""
        ""
        False
        False
        False
        ""
        False
        ! []


getPageFrom : Location -> Page
getPageFrom location =
    Homepage


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetPage location ->
            model ! []

        ToggleNavbar ->
            { model | expandedNavbar = not model.expandedNavbar } ! []

        SortBy sortOption ->
            -- if sortOption == model.sortOption then
            --     { model | sortAscending = not model.sortAscending } ! []
            -- else
            { model | sortOption = sortOption } ! []

        MakeSquigg ->
            case model.user of
                Just user ->
                    { model | creatingSquigg = True } ! [ createSquigg user model ]

                Nothing ->
                    model ! []

        MakeSquiggRespond (Ok response) ->
            if response.error then
                { model | creatingSquigg = False } ! []
            else
                { model
                    | creatingSquigg = False
                    , draft = ""
                    , squiggs = response.data ++ model.squiggs
                }
                    ! []

        MakeSquiggRespond (Err _) ->
            model ! []

        Update DraftSquigg draft ->
            { model | draft = draft } ! []

        Update Username username ->
            { model | username = username } ! []

        Update Password password ->
            { model | password = password } ! []

        ToggleSignInForm ->
            { model | showSignInForm = not model.showSignInForm } ! []

        SignInClicked ->
            { model | signingIn = True, signInError = "" } ! [ signIn model ]

        SignUpClicked ->
            { model | signingUp = True, signInError = "" } ! [ signUp model ]

        SignOutClicked ->
            model ! [ signOut ]

        SignInRespond (Ok response) ->
            if response.error then
                { model
                    | signingIn = False
                    , signInError = response.message
                }
                    ! []
            else
                { model
                    | signingIn = False
                    , showSignInForm = False
                    , user = List.head response.data
                }
                    ! []

        SignInRespond (Err err) ->
            let
                _ =
                    Debug.log "Sign in error" err
            in
            { model | signingIn = False, signInError = "Oops! We has a problem. Please try again." } ! []

        SignOutRespond (Ok response) ->
            if response.error then
                let
                    _ =
                        Debug.log "Sign out error" response.error
                in
                model ! []
            else
                { model
                    | user = Nothing
                }
                    ! []

        SignOutRespond (Err err) ->
            let
                _ =
                    Debug.log "Sign in error" err
            in
            model ! []


createSquigg : User -> { a | draft : String } -> Cmd Msg
createSquigg user { draft } =
    Http.send MakeSquiggRespond
        (Http.post "/api/squiggs" (squiggBody user draft) (responseDecoder squiggDecoder))


squiggBody : User -> String -> Http.Body
squiggBody user content =
    Http.jsonBody
        (Encode.object
            [ ( "content", Encode.string content )
            , ( "user", Encode.string user.id )
            ]
        )


signIn : Credentials a -> Cmd Msg
signIn =
    signInUpHelper "sign-in"


signUp : Credentials a -> Cmd Msg
signUp =
    signInUpHelper "sign-up"


signOut : Cmd Msg
signOut =
    Http.send SignOutRespond (Http.post "/api/sign-out" Http.emptyBody (responseDecoder Decode.string))


signInUpHelper : String -> Credentials a -> Cmd Msg
signInUpHelper endpoint credentials =
    Http.send
        SignInRespond
        (Http.post ("/api/" ++ endpoint) (bodyFromCredentials credentials) (responseDecoder userDecoder))


bodyFromCredentials : Credentials a -> Http.Body
bodyFromCredentials { username, password } =
    Http.jsonBody
        (Encode.object
            [ ( "username", Encode.string <| username )
            , ( "password", Encode.string <| password )
            ]
        )


responseDecoder : Decode.Decoder a -> Decode.Decoder (ApiResponse a)
responseDecoder decoder =
    Decode.map3 ApiResponse
        (Decode.field "error" Decode.bool)
        (Decode.field "message" Decode.string)
        (Decode.field "data" (Decode.list decoder))


userDecoder : Decode.Decoder User
userDecoder =
    Decode.map User
        (Decode.field "id" Decode.string)


squiggDecoder : Decode.Decoder Squigg
squiggDecoder =
    Decode.map5 Squigg
        (Decode.field "id" Decode.string)
        (Decode.field "content" Decode.string)
        (Decode.field "user" Decode.string)
        (Decode.field "timestamp" Decode.string)
        (Decode.field "votes" (Decode.list Decode.string))


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
        [ viewNavbar model.draft ( model.sortOption, model.sortAscending ) model.expandedNavbar model.user
        , viewPage model
        , viewSignInModal model model
        ]


navbarTabs : List SortOption
navbarTabs =
    [ Top
    , Recent
    , Awful
    ]


type alias SortInfo =
    ( SortOption, Bool )


viewNavbar : String -> SortInfo -> Bool -> Maybe User -> Html Msg
viewNavbar draft sortInfo expandedNavbar user =
    nav [ class "navbar has-shadow" ]
        [ div [ class "container" ]
            [ div [ class "navbar-brand" ]
                [ a [ class "navbar-item", href "/" ]
                    [ img [ src "/public/penguin.png", alt "baroot penguino" ] []
                    , h3 [ class "subtitle is-padded-left" ] [ baroot ]
                    ]
                , div
                    [ class "navbar-burger"
                    , classList [ ( "is-active", expandedNavbar ) ]
                    , onClick ToggleNavbar
                    ]
                    [ span [] [], span [] [], span [] [] ]
                ]
            , div [ class "navbar-menu", classList [ ( "is-active", expandedNavbar ) ] ]
                [ div [ class "navbar-start" ]
                    [ div [ class "nav-item tabs is-toggle is-marginless" ]
                        [ ul [] (List.map (viewNavbarTab sortInfo) navbarTabs)
                        ]
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
                            [ button
                                [ class "button is-link is-outlined"
                                , disabled True
                                ]
                                [ text "Your squiggs" ]
                            , button
                                [ class "button is-danger is-outlined"
                                , onClick SignOutClicked
                                ]
                                [ text "Sign out" ]
                            ]
                        )
                    ]
                ]
            ]
        ]


isValidPost : String -> Bool
isValidPost value_ =
    String.length value_ > 0


viewNewPostField : { a | draft : String, creatingSquigg : Bool } -> Html Msg
viewNewPostField { draft, creatingSquigg } =
    div [ class "field has-addons" ]
        [ div [ class "control", style [ ( "flex", "1" ) ] ]
            [ input
                [ class "input is-medium"
                , type_ "text"
                , onInput (Update DraftSquigg)
                , placeholder "Make a squigg"
                , value draft
                ]
                []
            ]
        , div [ class "control" ]
            [ if isValidPost draft then
                button [ class "button is-medium is-info", classList [ ( "is-loading", creatingSquigg ) ], onClick MakeSquigg ] [ text "Send" ]
              else
                button [ class "button is-medium", disabled True ] [ text "Send" ]
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


viewSquigg : Maybe User -> Squigg -> Html Msg
viewSquigg user squigg =
    div [ class "box" ]
        [ article [ class "media" ]
            [ div [ class "media-content" ]
                [ div [ class "content" ]
                    [ p []
                        [ small [ class "has-text-grey" ] [ text squigg.timestamp ]
                        , br [] []
                        , text squigg.content
                        ]
                    ]
                , div [ class "content" ] []
                ]
            ]
        ]


viewPage : { a | user : Maybe User, squiggs : List Squigg, page : Page, draft : String, creatingSquigg : Bool, sortOption : SortOption } -> Html Msg
viewPage { user, squiggs, page, draft, creatingSquigg, sortOption } =
    case page of
        Homepage ->
            div [ class "container", style [ ( "padding", "1rem" ) ] ]
                ([ if user /= Nothing then
                    viewNewPostField { draft = draft, creatingSquigg = creatingSquigg }
                   else
                    text ""
                 ]
                    ++ List.map (viewSquigg user) (List.sortWith (withSortOption sortOption) squiggs)
                )


withSortOption : SortOption -> Squigg -> Squigg -> Basics.Order
withSortOption sortOption a b =
    case sortOption of
        _ ->
            if List.length a.votes < List.length b.votes then
                Basics.LT
            else
                Basics.GT


viewSignInModal : SigningInStatus a -> Credentials b -> Html Msg
viewSignInModal signInStatus credentials =
    div [ class "modal", classList [ ( "is-active", signInStatus.showSignInForm ) ] ]
        [ div
            [ class "modal-background"
            , onClick ToggleSignInForm
            ]
            []
        , div [ class "modal-content" ]
            [ viewSignInForm signInStatus credentials
            ]
        , div
            [ class "modal-close is-large"
            , attribute "aria-label" "close"
            , onClick ToggleSignInForm
            ]
            []
        ]


viewSignInForm : SigningInStatus a -> Credentials b -> Html Msg
viewSignInForm { signingIn, signingUp, signInError } { username, password } =
    div [ class "box" ]
        [ viewFormInput "text" "Username" (Update Username) username
        , viewFormInput "password" "Password" (Update Password) password
        , hr [] []
        , div [ class "field is-grouped is-grouped-right" ]
            ([ p [ class "control" ]
                (if String.length signInError > 0 then
                    [ span [ class "tag is-danger" ] [ text signInError ] ]
                 else
                    []
                )
             ]
                ++ (if isValidSignInForm username password then
                        [ p [ class "control" ]
                            [ button
                                [ class "button is-link"
                                , onClick SignUpClicked
                                , classList [ ( "is-loading", signingUp ) ]
                                ]
                                [ text "Join" ]
                            ]
                        , p [ class "control" ]
                            [ button
                                [ class "button is-info"
                                , onClick SignInClicked
                                , classList [ ( "is-loading", signingIn ) ]
                                ]
                                [ text "Sign in" ]
                            ]
                        ]
                    else
                        [ p [ class "control" ]
                            [ button [ class "button is-link", disabled True ] [ text "Join" ] ]
                        , p [ class "control" ]
                            [ button [ class "button is-info", disabled True ] [ text "Sign in" ] ]
                        ]
                   )
            )
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

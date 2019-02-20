import Browser
import Html
import Http
import Json.Encode as Encode
import Navigation


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view >> toUnstyled
        }


type alias Login =
     { usernameText : String
     , passwordText : String
     }


type alias Model = Login


postLogin : Login -> Cmd Msg
postLogin login =
          Http.post
                { url = "/login"
                , body = Http.jsonBody (loginEncoder login)
                , expect = Http.expectString
                }


loginEncoder : Login -> Encode.Value
loginEncoder login =
             Encode.object
             [ (Encode.string "username" login.usernameText)
             , (Encode.string "password" login.passwordText)
             ]


-- UPDATE


type Msg =
     = UsernameTextInput String
     | PasswordTextInput String
     | Submit
     | PostLogin (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
       case msg of
            UsernameTextInput username ->
                              ( { model | usernameText = username }, Cmd.none )

            PasswordTextInput password ->
                              ( { model | passwordText = password }, Cmd.none )

            Submit ->
             ( model, postLogin model )

            PostLogin result ->
                      case result of
                           Ok result ->
                              ( model, Navigation.load result )

                           Err _ ->
                               ( model, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
     div []
     [ input [ onInput UsernameTextInput, placeholder "Username", value.modelUsernameText] []
     , input [ onInput PasswordTextInput, placeholder "Password", value.modelPasswordText] []
     , button [ onClick Submit ] [ text "Submit" ]
     ]

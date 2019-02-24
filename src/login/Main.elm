import Browser
import Html
import Http
import Json.Encode as Encode
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Browser.Navigation as Nav


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


type alias Model =
    { usernameText : String
    , passwordText : String
    , errorMessage : String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model "" "" "", Cmd.none )

        
postLogin : Login -> Cmd Msg
postLogin login =
          Http.post
                { url = "/login"
                , body = Http.jsonBody (loginEncoder login)
                , expect = Http.expectString PostLogin
                }


loginEncoder : Login -> Encode.Value
loginEncoder login =
             Encode.object
                 [ ("username", Encode.string login.usernameText)
                 , ("password", Encode.string login.passwordText)
                 ]


-- UPDATE


type Msg
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
             ( model, postLogin { usernameText = model.usernameText, passwordText = model.passwordText} )

            PostLogin result ->
                      case result of
                           Ok url ->                              
                              ( model, Nav.load url )

                           Err _ ->
                               ( { model | errorMessage = "An error has occurred" }, Cmd.none )


-- VIEW


view : Model -> Html Msg
view model =
     div []
         [ input [ onInput UsernameTextInput, placeholder "Username", value model.usernameText ] []
         , input [ onInput PasswordTextInput, placeholder "Password", value model.passwordText ] []
         , button [ onClick Submit ] [ text "Submit" ]
         , text model.errorMessage
         ]

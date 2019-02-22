import Browser
import Html
import Http
import Json.Encode as Encode
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view >> toUnstyled
        }

        
-- MODEL


type alias Task =
    { id : Int
    , name : String
    , status : String
    }


type alias Model =
     { username : String
     , usernameEdit : String
     , tasks : List Task
     , editMode : Bool
     , todoCount : Int
     , onGoingCount : Int
     , doneCount : Int
     }


init : String -> ( Model, Cmd Msg )
init username =
    ( { username = username
      , usernameEdit = ""
      , tasks = []
      , editMode = False
      , todoCount = 0
      , onGoingCount = 0
      , doneCount = 0
      }
    , getTasks username
    )       


getTasks : String -> Cmd Msg
getTasks username =
    Http.get
        { url = ("/tasks/user/" ++ username)
        , expect = Http.expectJson GetTasks tasksDecoder
        }


countTodo : List Task -> Int
countTodo tasks =
    (List.filter (\t -> t.status == "Todo") tasks) |> List.length


countOnGoing : List Task -> Int
countOnGoing tasks =
    (List.filter (\t -> t.status == "OnGoing") tasks) |> List.length
        

countDone : List Task -> Int
countDone tasks =
    (List.filter (\t -> t.status == "Done") tasks) |> List.length
        
        
postUpdateUsername : String -> String -> Cmd Msg
postUpdateUsername oldUsername newUsername =
    Http.post
        { url = "/update/user/name"
        , body = Http.jsonBody (updateRequestEncoder oldUsername newUsername)
        , expect = Http.expectWhatever PostUpdateUsername
        }


updateRequestEncoder : String -> String -> Encode.Value
updateRequestEncoder old new =
    Encode.object
        [ ("old", Encode.string old)
        , ("new", Encode.string new)
        ]
        

tasksDecoder : Decode.Decoder (List Task)
tasksDecoder =
    Decode.list taskDecoder
        

taskDecoder : Decode.Decoder Task
taskDecoder =
    Decode.map3 Task
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "status" Decode.string)
        

-- UPDATE


type Msg
    = Submit
    | UsernameInput String
    | GetTasks (Result Http.Error (List Task))
    | PostUpdateUsername (Result Http.Error ())
    | Edit
      

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
       case msg of
           Edit ->
               ( { model | editMode = not model.editMode }, Cmd.none )
                       
           Submit ->
               ( model, postUpdateUsername model.username model.usernameEdit)

           UsernameInput u ->
               ( { model | usernameEdit = u }, Cmd.none )

           GetTasks result ->
               case result of
                   Ok tasks ->
                       ( { model | tasks = tasks, todoCount = countTodo tasks, onGoingCount = countOnGoing tasks, doneCount = countDone tasks }, Cmd.none )

                   Err _ ->
                       ( model, Cmd.none )

           PostUpdateUsername _ ->
               ( model, Cmd.none )


-- VIEW
       

view : Model -> Html Msg
view model =
     div []
         [ userView model
         , tasksView model
         ]


userView : Model -> Html Msg
userView model =
    if model.editMode then
        div []
            [ input [ value model.usernameEdit, onInput UsernameInput, placeholder model.username ] []
            , button [ onClick Submit ] [ text "Submit Edit" ]
            ]
    else
        div []
            [ text model.username
            , button [ onClick Edit ] [ text "Edit" ]
            ]


tasksView : Model -> Html Msg
tasksView model =
    div []
        [ div []
              [ text <| String.fromInt model.todoCount 
              , text <| String.fromInt model.onGoingCount
              , text <| String.fromInt model.doneCount
              ]
        , div []
            (List.map taskView model.tasks)
        ]

            
taskView : Task -> Html Msg
taskView task =
    div []
        [ div [] [ text task.name ]
        , div [] [ text task.status ]
        ]        

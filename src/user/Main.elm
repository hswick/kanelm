import Browser
import Html


main =
    Browser.element
        { init = init
        , update = 
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
     , tasks : List Task
     , editMode : Bool
     , todoCount : Int
     , onGoingCount : Int
     , doneCount : Int
     }


init : String -> ( Model, Cmd Msg )
init username =
     ( Model username, [], False, 0, 0, 0, getTasks username)


getTasks : String -> Cmd Msg
getTasks username =
    Http.get
        { url = ("/tasks/user/" ++ username)
        , expect = Http.expectJson GetTasks tasksDecoder
        }


countTodo : List Task -> Int
countTodo tasks =
    (List.filter \t -> t.status == "Todo") |> List.sum


countOnGoing : List Task ->
countOnGoing tasks =
    (List.filter \t -> t.status == "OnGoing") |> List.sum
        

countDone : List Task ->
countDone tasks =
    (List.filter \t -> t.status == "Done") |> List.sum)

        
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
        

tasksDecoder : Decode.Decoder List Task
tasksDecoder =
    Decode.list taskDecoder
        

taskDecoder : Decode.Decoder Task
taskDecoder =
    Decode.map4 Task
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
               ( { model | editMode = not editMode }, Cmd.none )
                       
           Submit ->
               ( model, postUpdateUsername model.username )

           UsernameInput u ->
               ( { model | username = u }, Cmd.none )

           GetTasks result ->
               case result of
                   Ok tasks ->
                       ( { model | tasks = tasks, todoCount countTodo tasks, onGoingCount = countOngoing tasks, doneCount = countDone tasks }, Cmd.none )

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
    div []
        if model.editMode then
            [ text username
            , input [ value model.username, onInput UsernameInput ] []
            , button [ onClick Submit ] [ text "Submit Edit" ]
            ]
        else
            [ text username
            , button [ onClick Edit ] [ text "Edit" ]
            ]


tasksView : Model -> Html Msg
tasksView model =
    div []
        [ div []
              [ text <| String.fromInt model.todoCount 
              , text <| String.fromint model.onGoingCount
              , text <| String.fromInt model.doneCount
              ]
        , div []
            List.map taskView tasks
        ]

            
taskView : Task -> Html Msg
taskView task =
    div []
        [ div [] [ text task.name ]
        , div [] [ text task.status ]
        ]        

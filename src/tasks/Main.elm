import Browser
import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)
import Http
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


type alias ActiveProject =
    { projectId : Int
    , projectName : String
    , userId : Int
    , userName : String
    , accessToken : String
    }
    
type alias Model =
    { taskInput : String
    , tasks : List Task
    , project : ActiveProject
    }


init : ActiveProject -> ( Model, Cmd Msg )
init project =
    ( Model "" [] project, getTasks )


getOnGoingTasks : Model -> List Task
getOnGoingTasks model =
    List.filter (\t -> t.status == "OnGoing") model.tasks


getToDoTasks : Model -> List Task
getToDoTasks model =
    List.filter (\t -> t.status == "Todo") model.tasks


getDoneTasks : Model -> List Task
getDoneTasks model =
    List.filter (\t -> t.status == "Done") model.tasks        


getTasks : Cmd Msg
getTasks =
    Http.get
        { url = "/tasks"
        , expect = Http.expectJson GetTasks tasksDecoder
        }


postNewTask : String -> Cmd Msg
postNewTask name =
    Http.post
        { url = "/new"
        , body = Http.jsonBody (newTaskEncoder name)
        , expect = Http.expectJson PostNewTask taskDecoder
        }
        
        
postMoveTask : Task -> Cmd Msg
postMoveTask task =
    Http.post
        { url = "/move"
        , body = Http.jsonBody (taskEncoder task)
        , expect = Http.expectWhatever PostMoveTask 
        }

        
postDeleteTask : Task -> Cmd Msg
postDeleteTask task =
    Http.post
        { url = "/delete"
        , body = Http.jsonBody (taskEncoder task)
        , expect = Http.expectWhatever PostDeleteTask 
        }


tasksDecoder : Decode.Decoder (List Task)
tasksDecoder =
    Decode.list taskDecoder


taskDecoder : Decode.Decoder Task
taskDecoder =
    Decode.map3 Task
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "status" Decode.string)


taskEncoder : Task -> Encode.Value
taskEncoder task =
    Encode.object
        [ ("id", Encode.int task.id)
        , ("name", Encode.string task.name)
        , ("status", Encode.string task.status)
        ]

        
newTaskEncoder : String -> Encode.Value
newTaskEncoder name =
    Encode.object
        [ ("name", Encode.string name) ]
            

-- UPDATE


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Decode.map tagger keyCode)


type Msg
    = KeyDown Int
    | TextInput String
    | Delete Task
    | MoveLeft Task
    | MoveRight Task
    | GetTasks (Result Http.Error (List Task))
    | PostNewTask (Result Http.Error Task)
    | PostMoveTask (Result Http.Error ())
    | PostDeleteTask (Result Http.Error ())


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyDown key ->
            if key == 13 then
                ( model, postNewTask model.taskInput )

            else
                ( model, Cmd.none )

        TextInput content ->
            ( { model | taskInput = content }, Cmd.none )

        Delete task ->
            ( { model | tasks = List.filter (\x -> x.id /= task.id) model.tasks }, postDeleteTask task )

        MoveRight task ->
            case task.status of
                "Todo" ->
                    moveTask model task "OnGoing"

                "OnGoing" ->
                    moveTask model task "Done"

                _ ->
                    ( model, Cmd.none )

        MoveLeft task ->
            case task.status of
                "OnGoing" ->
                    moveTask model task "Todo"

                "Done" ->
                    moveTask model task "OnGoing"

                _ ->
                    ( model, Cmd.none )

        GetTasks result ->
            case result of
                Ok tasks ->
                    ( { model | tasks = tasks }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        PostNewTask result ->
            case result of
                Ok task ->
                    ( { model | tasks = task :: model.tasks, taskInput = "" }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        PostMoveTask _ ->
            ( model, Cmd.none )

        PostDeleteTask _ ->
            ( model, Cmd.none )            


moveTask : Model -> Task -> String -> ( Model, Cmd Msg )
moveTask model task newStatus =
    ( { model | tasks = moveTaskToStatus task newStatus model.tasks }, postMoveTask (Task task.id task.name newStatus) )

        
moveTaskToStatus : Task -> String -> List Task -> List Task
moveTaskToStatus taskToFind newTaskStatus tasks =
    List.map
        (\t ->
            if t.id == taskToFind.id then
                { t | status = newTaskStatus }

            else
                t
        )
        tasks
                        

-- VIEW


view : Model -> Html Msg
view model =
    let
        todos =
            getToDoTasks model

        ongoing =
            getOnGoingTasks model

        dones =
            getDoneTasks model
    in
    div
        [ class "container dark"
        , css
            [ Css.width (pct 100)
            , Css.height (pct 100)
            , margin (px 0)
            , padding (px 0)
            , boxSizing borderBox
            , displayFlex
            , flexDirection column
            , backgroundColor (hex "f6f6f6")
            ]
        ]
        [ input
            [ type_ "text"
            , class "task-input"
            , placeholder "What's on your mind right now?"
            , tabindex 0
            , onKeyDown KeyDown
            , onInput TextInput
            , value model.taskInput
            , css
                [ padding (px 10)
                , Css.height (px 50)
                , fontSize (px 16)
                , borderStyle none
                , boxShadow4 zero (px 1) (px 1) (rgba 0 0 0 0.1)
                ]
            ]
            []
        , div
            [ class "kanban-board"
            , css
                [ flex (int 1)
                , displayFlex
                , flexDirection row
                ]
            ]
            [ taskColumnView "Todo" todos
            , taskColumnView "OnGoing" ongoing
            , taskColumnView "Done" dones
            ]
        ]


statusStyle : String -> Style
statusStyle status =
    case status of
        "Ongoing" ->
            borderLeft3 (px 5) solid (hex "f39c12")

        "Todo" ->
            borderLeft3 (px 5) solid (hex "e74c3c")

        "Done" ->
            borderLeft3 (px 5) solid (hex "2ecc71")

        _ ->
            borderLeft2 (px 5) solid


taskItemView : Int -> Task -> Html Msg
taskItemView index task =
    li
        [ class "task-item"
        , css
            [ fontSize (px 14)
            , marginBottom (px 10)
            , padding4 (px 15) (px 40) (px 15) (px 15)
            , backgroundColor (hex "FFF")
            , boxShadow4 zero (px 1) (px 1) (rgba 0 0 0 0.1)
            , borderRadius (px 3)
            , cursor move
            , position relative
            , statusStyle task.status
            ]
        ]
        [ buttonHeader task
        , text task.name
        ]


buttonHeader : Task -> Html Msg
buttonHeader task =
    let
        buttons =
            case task.status of
                "Todo" ->
                    [ deleteButton task, moveRightButton task ]

                "Done" ->
                    [ deleteButton task, moveLeftButton task ]

                _ ->
                    [ deleteButton task, moveLeftButton task, moveRightButton task ]
    in
        div [ css [ float right ] ] buttons


buttonStyling : List Style
buttonStyling =
    [ backgroundColor (hex "e74c3c")
    , color (hex "fff")
    , Css.width (px 30)
    , Css.height (px 30)
    , borderStyle none
    , borderRadius (px 10)
    , fontSize (px 20)
    , hover [ opacity (num 1) ]
    ]


deleteButton : Task -> Html Msg
deleteButton task =
    button
        [ class "btn-delete"
        , onClick <| Delete task
        , css buttonStyling
        ]
        [ text "-" ]


moveLeftButton : Task -> Html Msg
moveLeftButton task =
    button
        [ onClick <| MoveLeft task
        , css buttonStyling
        ]
        [ text "<" ]


moveRightButton : Task -> Html Msg
moveRightButton task =
    button
        [ onClick <| MoveRight task
        , css buttonStyling
        ]
        [ text ">" ]


taskColumnView : String -> List Task -> Html Msg
taskColumnView status list =
    div
        [ class <| "category " ++ String.toLower status
        , css
            [ flex (int 1)
            , margin (px 10)
            , padding (px 10)
            ]
        ]
        [ h2
            [ css
                [ margin (px 0)
                , padding (px 0)
                , fontSize (px 16)
                , textTransform uppercase
                ]
            ]
            [ text status ]
        , span
            [ css
                [ fontSize (px 14)
                , color (hex "aaa")
                ]
            ]
            [ text (String.fromInt (List.length list) ++ " item(s)") ]
        , ul
            [ css
                [ margin2 (px 10) zero
                , padding (px 0)
                , listStyle none
                ]
            ]
            (List.indexedMap taskItemView list)
        ]

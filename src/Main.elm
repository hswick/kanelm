import Browser

import Css exposing (..)
import Css.Transitions exposing (transition)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)

import Json.Decode as Decode


main =
     Browser.element
     { init = init
     , update = update
     , subscriptions = (always Sub.none)
     , view = view >> toUnstyled
     }


-- MODEL


type alias Task =
    { name: String
    , status: String
    }


type alias Model =
    { taskInput: String
    , tasks: List Task
    }


init : () -> ( Model, Cmd msg )
init _ =
    ( Model "" [], Cmd.none )


moveTaskToStatus : Task -> String -> List Task -> List Task
moveTaskToStatus taskToFind newTaskStatus tasks =
  List.map (\t -> 
    if t.name == taskToFind.name then
       { t | status = newTaskStatus }
    else
       t
     ) tasks


deleteTask : Model -> String -> ( Model, Cmd Msg )
deleteTask model name =
    ( { model | tasks = List.filter (\x -> x.name /= name) model.tasks }, Cmd.none )


getOnGoingTasks : Model -> List Task
getOnGoingTasks model =
  List.filter (\t -> t.status == "OnGoing") model.tasks

      
getToDoTasks : Model -> List Task
getToDoTasks model =
  List.filter (\t -> t.status == "Todo") model.tasks

      
getDoneTasks : Model -> List Task
getDoneTasks model =
  List.filter (\t -> t.status == "Done") model.tasks
      
      
-- UPDATE


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger = on "keydown" (Decode.map tagger keyCode)


type Msg =
    KeyDown Int
    | TextInput String
    | Delete String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of

    KeyDown key ->
      if key == 13 then
        ( { model | tasks = ( Task model.taskInput "Todo" ) :: model.tasks, taskInput = "" }, Cmd.none )
      else
        ( model, Cmd.none )

    TextInput content ->
       ( { model | taskInput = content }, Cmd.none )

    Delete content -> deleteTask model content


-- VIEW                      
                      

view : Model -> Html Msg
view model =
  let
      todos = getToDoTasks model
      ongoing = getOnGoingTasks model
      dones = getDoneTasks model
  in
      div [ class "container dark"
          , css [ Css.width (pct 100)
                , Css.height (pct 100)
                , margin (px 0)
                , padding (px 0)
                , (boxSizing borderBox)
                , displayFlex
                , flexDirection column
                , backgroundColor (hex "f6f6f6")
                ]
          ]
          [ input [ type_ "text"
                  , class "task-input"
                  , placeholder "What's on your mind right now?"
                  , tabindex 0
                  , onKeyDown KeyDown
                  , onInput TextInput
                  , value model.taskInput
                  , css [ padding (px 10)
                        , Css.height (px 50)
                        , fontSize (px 16)
                        , borderStyle none
                        , boxShadow4 zero (px 1) (px 1) (rgba 0 0 0 0.1)
                        ]
                  ] [ ]
          , div [ class "kanban-board"
                , css [ flex (int 1)
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
  li [ class "task-item"
     , css [ fontSize (px 14)
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
     [ text task.name
     , button [ class "btn-delete"
              , onClick <| Delete task.name
              , css [ display block
                    , backgroundColor (hex "e74c3c")
                    , color (hex "fff")
                    , Css.width (px 30)
                    , Css.height (px 30)
                    , borderStyle none
                    , borderRadius (px 11)
                    , position absolute
                    , top (pct 50)
                    , right (px 10)
                    , marginTop (px -11)
                    , opacity (num 0.05)
                    , cursor pointer
                    , transition [ Css.Transitions.opacity 0.5 ]
                    , fontSize (px 20)
                    , lineHeight (px 24)
                    , textIndent (px -3)
                    , hover [ opacity (num 1) ]
                    ]
              ][ text "-" ]
     ]

      
-- COLUMN VIEW


taskColumnView : String -> List Task -> Html Msg
taskColumnView status list =
  div
  [ class <| "category " ++ String.toLower status
  , css [ flex (int 1)
        , margin (px 10)
        , padding (px 10)
        ]
  ]
  [ h2 [ css [ margin (px 0)
             , padding (px 0)
             , fontSize (px 16)
             , textTransform uppercase
             ]
       ]
       [ text status ]
  , span [ css [ fontSize (px 14)
               , color (hex "aaa")
               ]
         ]
         [ text (String.fromInt (List.length list) ++ " item(s)") ]
  , ul [ css [ margin2 (px 10) zero
             , padding (px 0)
             , listStyle none
             ]
       ]
      (List.indexedMap taskItemView list)
  ]

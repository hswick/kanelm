import Browser

import Css exposing (..)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)

import Models exposing (..)
import Views exposing (..)
import EventHelpers exposing (..)

main =
     Browser.element
     { init = initModel
     , update = update
     , subscriptions = (always Sub.none)
     , view = view >> toUnstyled
     }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp ->
      ( model, Cmd.none )

    KeyDown key ->
      if key == 13 then
         addNewTask model
      else
        ( model, Cmd.none )

    TextInput content ->
       ( { model | taskInput = content }, Cmd.none )

    Move selectedTask ->
      ( { model | movingTask = Just selectedTask }, Cmd.none )

    DropTask targetStatus -> moveTask model targetStatus

    Delete content -> deleteTask model content


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

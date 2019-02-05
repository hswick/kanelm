module Views exposing (..)

import Css exposing (..)
import Css.Transitions exposing (transition)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Html.Styled.Events exposing (..)

import Models exposing (..)
import EventHelpers exposing (..)

-- CARD VIEW

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
     , attribute "draggable" "true"
     , onDragStart <| Move task
     , attribute "ondragstart" "event.dataTransfer.setData('text/plain', '')"
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
                    , fontSize (px 25)
                    , lineHeight (px 24)
                    , textIndent (px -3)
                    , transform (rotateZ (deg 45))
                    , hover [ opacity (num 1) ]
                    ]
              ][ text "-" ]
     ]

-- COLUMN VIEW

taskColumnView : String -> List Task -> Html Msg
taskColumnView status list =
  div
  [ class <| "category " ++ String.toLower status
  , attribute "ondragover" "return false"
  , onDrop <| DropTask status
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

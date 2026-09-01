-----------------------------------------------------------------------------
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE StaticPointers #-}

-----------------------------------------------------------------------------

{- |
Module      : Main
Description : miso-native giacenza calculator (LynxJS)
Copyright   : (c) 2026, paolino
License     : BSD-3-Clause

Paste path of the giacenza calculator as a miso-native dual-thread
component: an X @\<textarea\>@ for the CSV paste, tap-cycling date and
amount column selectors, a European\/American format toggle, and a
per-year table of saldo (31 Dec balance) and giacenza (average daily
balance). All tap\/input handlers are plain background (BTS) attributes
as required by the dual-thread runtime; the mount registers both the
built-in and X-element event maps because the paste area is an X
@\<textarea\>@. The domain is 'Giacenza.Parse' and 'Giacenza.Compute' —
no second parser and no second average-balance formula lives here.
-}
module Main (main) where

import Data.Map.Strict qualified as Map
import GHC.Generics (Generic)
import Giacenza.Compute (yearResults)
import Giacenza.Parse (CsvTable (..), extractMovements, parseCsv)
import Giacenza.Types
import Miso hiding (headers, text_)
import Miso.CSS qualified as CSS
import Miso.Html.Property (id_)
import Miso.JSON (FromJSON, ToJSON)
import Miso.Native
import Miso.Native.Element.View.Event qualified as VE
import Miso.Native.X.Element (textarea_)
import Miso.Native.X.Element.Input.Property (placeholder_)
import Miso.Native.X.Element.Textarea.Event qualified as TaE
import Miso.String (MisoString, fromMisoString, ms)
import Numeric (showFFloat)

-----------------------------------------------------------------------------
-- Model

{- | UI state: the paste, the detected headers with the selected date and
amount columns, the number format (European is the default, FR-003),
and the last compute outcome.
-}
data Model = Model
    { pasted :: MisoString
    , headerNames :: [MisoString]
    , dateIdx :: Int
    , amountIdx :: Int
    , european :: Bool
    , outcome :: Outcome
    }
    deriving stock (Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | Either nothing computed yet, a visible error, or the per-year table.
data Outcome
    = Idle
    | Failed MisoString
    | Computed [YearRow]
    deriving stock (Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

{- | One year row: year, giacenza, saldo (FR-007 order), amounts rendered
with two decimal places.
-}
data YearRow = YearRow
    { rowYear :: Int
    , rowGiacenza :: MisoString
    , rowSaldo :: MisoString
    }
    deriving stock (Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

-- | UI actions: the paste input and the taps (FR-003).
data Action
    = CsvInputChanged MisoString
    | CycleDateColumn
    | CycleAmountColumn
    | ToggleNumberFormat
    | ComputeRequested
    deriving stock (Eq, Generic)
    deriving anyclass (ToJSON, FromJSON)

initialModel :: Model
initialModel =
    Model
        { pasted = ""
        , headerNames = []
        , dateIdx = 0
        , amountIdx = 0
        , european = True
        , outcome = Idle
        }

-----------------------------------------------------------------------------
-- Update

updateModel :: Action -> Effect () () Model Action
updateModel = \case
    CsvInputChanged value ->
        modify $ \m ->
            m
                { pasted = value
                , headerNames = detectedHeaders value
                , dateIdx = 0
                , amountIdx = defaultAmountIdx (detectedHeaders value)
                , outcome = Idle
                }
    CycleDateColumn ->
        modify $ \m -> m{dateIdx = nextIdx (dateIdx m) (headerNames m)}
    CycleAmountColumn ->
        modify $ \m -> m{amountIdx = nextIdx (amountIdx m) (headerNames m)}
    ToggleNumberFormat ->
        modify $ \m -> m{european = not (european m)}
    ComputeRequested ->
        modify $ \m -> m{outcome = computeOutcome m}

{- | After a paste, the headers of the parsed paste; empty when the paste
does not parse at all.
-}
detectedHeaders :: MisoString -> [MisoString]
detectedHeaders value = case parseCsv (fromMisoString value) of
    Right table -> map ms (headers table)
    Left _ -> []

-- | The amount column defaults to the second header when one exists.
defaultAmountIdx :: [a] -> Int
defaultAmountIdx hdrs
    | null hdrs = 0
    | otherwise = min 1 (length hdrs - 1)

-- | Cycle to the next header; a no-op index when there are none.
nextIdx :: Int -> [a] -> Int
nextIdx i hdrs
    | null hdrs = 0
    | otherwise = (i + 1) `mod` length hdrs

{- | Run the full paste pipeline: parseCsv, extractMovements, yearResults.
A failure anywhere becomes a visible error and no numbers are shown.
-}
computeOutcome :: Model -> Outcome
computeOutcome m = case parseCsv (fromMisoString (pasted m)) of
    Left err -> Failed (ms (renderParseError err))
    Right table ->
        case extractMovements (configFor m) table of
            Left err -> Failed (ms (renderParseError err))
            Right movements -> Computed (renderRows (yearResults movements))

configFor :: Model -> Config
configFor m =
    Config
        { configNumberFormat = if european m then European else American
        , configDateColumn = selectedAt (dateIdx m)
        , configAmountColumn = selectedAt (amountIdx m)
        }
  where
    selectedAt i =
        case drop i (headerNames m) of
            (h : _) -> fromMisoString h
            [] -> ""

-- | Per-year rows in year order; saldo and giacenza with two decimals.
renderRows :: Result -> [YearRow]
renderRows (Result mp) =
    [ YearRow
        { rowYear = fromIntegral (unYear y)
        , rowGiacenza = showMoney (unValue g)
        , rowSaldo = showMoney (unValue s)
        }
    | (y, (Saldo s, Giacenza g)) <- Map.toAscList mp
    ]

showMoney :: Double -> MisoString
showMoney v = ms (showFFloat (Just 2) v "")

-----------------------------------------------------------------------------
-- View

viewModel :: () -> () -> Model -> View () Model Action
viewModel _ _ m =
    view_
        [ id_ "root"
        , CSS.style_
            [ CSS.width "100%"
            , CSS.height "100vh"
            , CSS.display "flex"
            , CSS.flexDirection "column"
            , CSS.padding "16px"
            , CSS.backgroundColor (CSS.RGB 15 23 42)
            ]
        ]
        [ text_
            [ CSS.style_
                [ CSS.fontSize "22px"
                , CSS.fontWeight "700"
                , CSS.color CSS.white
                , lineH
                , CSS.marginBottom "10px"
                ]
            ]
            [text "Giacenza calculator"]
        , pasteArea (pasted m)
        , controls m
        , outcomeView (outcome m)
        ]

-- | The CSV paste area (FR-001: paste only, no file picker).
pasteArea :: MisoString -> View () Model Action
pasteArea value =
    textarea_
        [ id_ "paste-area"
        , placeholder_ "paste a CSV with date and amount columns"
        , TaE.onInput (CsvInputChanged . TaE.textareaValue)
        , CSS.style_
            [ CSS.height "120px"
            , CSS.width "100%"
            , CSS.fontSize "14px"
            , CSS.backgroundColor CSS.white
            , CSS.padding "8px"
            , CSS.borderRadius "8px"
            , CSS.marginBottom "10px"
            ]
        ]

-- | Column selectors (tap cycles headers), format toggle, compute button.
controls :: Model -> View () Model Action
controls m =
    view_
        [ CSS.style_
            [ CSS.display "flex"
            , CSS.flexDirection "row"
            , CSS.marginBottom "10px"
            ]
        ]
        [ chip
            "date-col"
            (columnLabel (headerNames m) "Date" (dateIdx m))
            CycleDateColumn
        , chip
            "amount-col"
            (columnLabel (headerNames m) "Amount" (amountIdx m))
            CycleAmountColumn
        , chip "format-toggle" (formatLabel (european m)) ToggleNumberFormat
        , chip "compute-btn" "Compute" ComputeRequested
        ]

columnLabel :: [MisoString] -> MisoString -> Int -> MisoString
columnLabel hdrs kind i = kind <> ": " <> pickAt i hdrs

-- | The currently selected header, or a dash when nothing is selectable.
pickAt :: Int -> [MisoString] -> MisoString
pickAt i hdrs = case drop i hdrs of
    (h : _) -> h
    [] -> "—"

formatLabel :: Bool -> MisoString
formatLabel True = "Format: European"
formatLabel False = "Format: American"

-- | A tappable control chip with a stable id.
chip :: MisoString -> MisoString -> Action -> View () Model Action
chip hid lbl action =
    view_
        [ id_ hid
        , VE.onTap action
        , CSS.style_
            [ CSS.backgroundColor CSS.steelblue
            , CSS.borderRadius "8px"
            , CSS.padding "10px"
            , CSS.marginRight "8px"
            ]
        ]
        [ text_
            [ CSS.style_
                [ CSS.fontSize "13px"
                , CSS.fontWeight "600"
                , CSS.color CSS.white
                , lineH
                ]
            ]
            [text lbl]
        ]

-- | Idle hint, visible error, or the per-year result table.
outcomeView :: Outcome -> View () Model Action
outcomeView = \case
    Idle ->
        text_
            [CSS.style_ [CSS.fontSize "13px", CSS.color CSS.gray, lineH]]
            [text "Paste a CSV, pick the columns, then compute."]
    Failed msg ->
        view_
            [ id_ "error"
            , CSS.style_
                [ CSS.backgroundColor (CSS.RGB 127 29 29)
                , CSS.borderRadius "8px"
                , CSS.padding "10px"
                , CSS.width "100%"
                ]
            ]
            [ text_
                [ CSS.style_
                    [CSS.fontSize "14px", CSS.color CSS.white, lineH]
                ]
                [text msg]
            ]
    Computed rows ->
        view_
            [ id_ "results"
            , CSS.style_
                [ CSS.width "100%"
                , CSS.display "flex"
                , CSS.flexDirection "column"
                ]
            ]
            (tableHeader : map tableRow rows)

tableHeader :: View () Model Action
tableHeader =
    tableRowOf
        [ cell "Year"
        , cell "Giacenza"
        , cell "Saldo"
        ]

tableRow :: YearRow -> View () Model Action
tableRow YearRow{..} =
    tableRowOf
        [ cell (ms (show rowYear))
        , cell rowGiacenza
        , cell rowSaldo
        ]

tableRowOf :: [View () Model Action] -> View () Model Action
tableRowOf =
    view_
        [ CSS.style_
            [ CSS.display "flex"
            , CSS.flexDirection "row"
            , CSS.width "100%"
            , CSS.marginBottom "4px"
            ]
        ]

cell :: MisoString -> View () Model Action
cell value =
    view_
        [CSS.style_ [CSS.width "30%"]]
        [ text_
            [ CSS.style_
                [CSS.fontSize "14px", CSS.color CSS.white, lineH]
            ]
            [text value]
        ]

lineH :: CSS.Style
lineH = CSS.lineHeight "1.4"

-----------------------------------------------------------------------------
-- Entrypoint

app :: Component () () Model Action
app = component initialModel updateModel viewModel

main :: IO ()
main =
    nativeWithContext
        (nativeEvents <> nativeXEvents)
        ()
        (static (mountStatic app))

module Page.EnhanceYou exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


viewEY : Html msg
viewEY =
    div []
        [ div []
            [ h3 [] [ text "Podcasts" ]
            , ul []
                [ li []
                    [ a
                        [ href "https://youtube.com/playlist?list=PLnFaMy9CvPK6bWz9qqXz0L3KEPoz0cvCA&si=Yja_o3e6TseF7qRp"
                        , target "blank"
                        ]
                        [ text "The Wellness Cafe by Trinity Tondelier" ]
                    ]
                , li []
                    [ a
                        [ href "https://open.spotify.com/show/0xKOhJLfnQTGkWqFSodeCA?si=8ff1d91583954bce"
                        , target "blank"
                        ]
                        [ text "Pursuit of Wellness by Dear Media" ]
                    ]
                , li []
                    [ a
                        [ href "https://open.spotify.com/show/2AlwVzVu5uFO2xvY10Fyq3?si=68ce2ec6c33b4f88"
                        , target "blank"
                        ]
                        [ text "Mindful Gratitude by Leslie D Riopel" ]
                    ]
                , li []
                    [ a
                        [ href "https://www.ted.com/podcasts/how-to-be-a-better-human"
                        , target "blank"
                        ]
                        [ text "How to Be a Better Human by TED and PRX" ]
                    ]
                , li []
                    [ a
                        [ href "https://open.spotify.com/show/4cExBr7Wsyl9UlXOalMmX3?si=ea30f73e46864551"
                        , target "blank"
                        ]
                        [ text "The Daily Gratitude Minute by Scott Colby" ]
                    ]
                ]
            , img
                [ src "../../images/headphones.png"
                , alt "A pair of headphones"
                , width 100
                , height 100
                ]
                []
            ]
        , div []
            [ h3 [] [ text "Social Media Accounts" ]
            , h4 [] [ text "Instagram" ]
            , ul []
                [ li []
                    [ a
                        [ href "https://www.instagram.com/opentalk__/"
                        , target "blank"
                        ]
                        [ text "@opentalk_" ]
                    ]
                , li []
                    [ a
                        [ href "https://www.instagram.com/wetheurban/"
                        , target "blank"
                        ]
                        [ text "@wetheurban" ]
                    ]
                , li []
                    [ a
                        [ href "https://www.instagram.com/collectiveworld/"
                        , target "blank"
                        ]
                        [ text "@collectiveworld" ]
                    ]
                ]
            , h4 [] [ text "X" ]
            , ul []
                [ li []
                    [ a
                        [ href "https://x.com/GratitudeSoup"
                        , target "blank"
                        ]
                        [ text "@GratitudeSoup" ]
                    ]
                , li []
                    [ a
                        [ href "https://x.com/WomensHealthMag"
                        , target "blank"
                        ]
                        [ text "@WomensHealthMag" ]
                    ]
                , li []
                    [ a
                        [ href "https://x.com/MensHealthMag"
                        , target "blank"
                        ]
                        [ text "@MensHealthMag" ]
                    ]
                , li []
                    [ a
                        [ href "https://x.com/optmlhlthnwllns"
                        , target "blank"
                        ]
                        [ text "@optmlhlthnwllns" ]
                    ]
                ]
            , img
                [ src "../../images/social-media.png"
                , alt "Social media messages"
                , width 100
                , height 100
                ]
                []
            ]
        , div []
            [ h3 [] [ text "Inspirational Text" ]
            , ul []
                [ li []
                    [ a
                        [ href "https://www.amazon.com/Power-Letting-Go-John-Purkiss/dp/1783253630/"
                        , target "blank"
                        ]
                        [ text "The Power of Letting Go by John Purkiss" ]
                    ]
                , li []
                    [ a
                        [ href "https://www.amazon.com/Happiness-Project-Tenth-Anniversary-Aristotle/dp/0062888749/"
                        , target "blank"
                        ]
                        [ text "The Happiness Project by Gretchen Rubin" ]
                    ]
                , li []
                    [ a
                        [ href "https://www.amazon.com/Never-Finished-Unshackle-Your-Within/dp/1544534078/"
                        , target "blank"
                        ]
                        [ text "Never Finished by David Goggins" ]
                    ]
                , li []
                    [ a
                        [ href "https://www.amazon.com/Mountain-You-Transforming-Self-Sabotage-Self-Mastery/dp/1949759229/"
                        , target "blank"
                        ]
                        [ text "The Mountain is You by Brianna Wiest" ]
                    ]
                , li []
                    [ a
                        [ href "https://www.amazon.com/Strength-Our-Scars-Bianca-Sparacino/dp/0996487190/"
                        , target "blank"
                        ]
                        [ text "The Strength in Our Scars by Bianca Sparacino" ]
                    ]
                ]
            , img
                [ src "../../images/books.png"
                , alt "A collection of books"
                , width 100
                , height 100
                ]
                []
            ]
        ]

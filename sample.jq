include "./jq-file";
import "./json-data" as $data;

# Function definition
def join_columns_const($c1; $c2; $const):
  [ $c1, $c2 ] | transpose | reduce .[] as [$c1_item, $c2_item] (
    {items:[], count: 0};
    items += [ [$c1_item, $c2_item, $const] ] | .count += 1
  )
;

# Variable definition
(
  if [.. | strings | contains("TEST_DATA") ] | any ) then
    "TEST_DATA"
  else
    "VAR_DATA"
  end
) as $data_type |

# Object filter
{
    keep_key,
    override_key: "override_value",
    upcase: ( .content[] | join("\n") | ascii_upcase ),
    json_string_export: ( . | @json "Content[0] JSON string: \( .content[0] | only_white_inside_interpolated_strings | ascii_upcase)" ),
    data_type: $data_type,
    "literal_key": "string_value",
    "number": 12.1e12,
    "misc": {
        "hello": 12,
        goodbye: "darkness my old friend"
    }
} | (

    # Basic invalid brace matching

    # Invalid End example
    ]

    # Other Invalid End examples
    ( [ } ] )

    # A "valid" sequence
    ( [  { key_1: () , key_2:( [ []  [[]] ]  ), key_3 }  ] )

    # An "invalid" sequence
    ( [  { key_1: () , key_2:( [ []  [[] ]  ), key_3 }  ] )

    "Escaped characters are also highlighted\n\"Like This\", unicode escape sequences only partially highlighted: \ud83d\ude14"
)

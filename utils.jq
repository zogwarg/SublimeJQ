# Math Ceil
def ceil:
   ( if . == floor then . else floor + 1 end )
;

# Provides the last three items and the array length
def array_summary:
  ( arrays | { count: length, sample: ["...", .[-3:]?[] ] } )
;

# Slices an array into groups of size n
def each_slice($n): (
  . as $a |
  (length) as $l |
  [ range($l / $n) | $a[(.*$n):(. *$n + $n)] ]
);

# Slices an array into n slices
def groups_slice($n): (
  . as $a |
  (length) as $l |
  (($l / $n) | ceil) as $s |
  each_slice($s)
);

# Exports an array into matlab format
# Invoke with jq -r
def save_matlab($name):
    ( if (.[0] | type == "array") then . else [.] end ) | 
    "# Saved from jq at \(now | todate)",
    "# name: \($name)",
    "# type: matrix",
    "# rows: \(length)",
    "# columns: \(.[0] | length)",
    "\(.[] | map(tostring) | join(" "))"
;

# Parse "2019-07-03T02:15:10.256Z"
# Dates with milliseconds, with epoch in milliseconds
def millifromdate:
    ( .[0:19] + .[-1:] | fromdate ) * 1000 + ( .[20:23] | tonumber )
;

# Cosine Similarity between to arrays
def cosine_sim($a; $b): (
    [ $a , $b ] |
    ( transpose | map(.[0] * .[1]) | add  ) / ( 
        ( $a | map(. * .) | add | sqrt ) * 
        ( $b | map(. * .) | add | sqrt ) 
    )
);

# Zeroes matrix of dimensions $a, and $b
def zeroes($a; $b): (
    ([range($b)] | map(0)) as $row |
    ([range($a)] | map($row))
);

# Implements math abs
def abs:
    (if . >= 0 then . else -. end)
;

# Non zero, all check
def any_all:
    ( any and all )
;

# Sort dictionaries by key
def sort_object: 
    ( to_entries | sort_by(.key) | from_entries )
;

# Round to last 2 digits.
def round2: (
    ( floor | tostring ) + (( . - floor ) * 100  | floor | "." + tostring )
);

# Have log as 1-ary function
def log($n):
    ($n | log)
;

# Format numbers
def num_fmt($f):
    . as $input |
    if ( . | numbers ) and $f == "iec" then
        (logi(.) / logi(1024)) as $group |
        if $group < 1 then
            round2 | tostring
        elif $group < 2 then
            (. / 1024 | round2 ) + "K"
        elif $group < 3 then
            (. / 1048576 | round2 ) + "M"
        else
            (. / 1073741824 | round2 ) + "G"
        end
    elif ( . | numbers ) and $f == "si" then
        (logi(.) / logi(1000)) as $group |
        if $group < 1 then
            round2 | tostring
        elif $group < 2 then
            (. / 1000 | round2 ) + "K"
        elif $group < 3 then
            (. / 1000000 | round2 ) + "M"
        else
            (. / 1000000000 | round2 ) + "G"
        end
    else
    "error"
    end
;

# Urldecode
def urldecode:
  def unhex:
    if 48 <= . and . <= 57 then . - 48 elif 65 <= . and . <= 70 then . - 55 else . - 87 end;

  def bytes:
    def loop($i):
      if $i >= length then empty else 16 * (.[$i+1] | unhex) + (.[$i+2] | unhex), loop($i+3) end;
    [loop(0)];

  def codepoints:
    def loop($i):
      if $i >= length then empty
      elif .[$i] >= 240 then (.[$i+3]-128) + 64*(.[$i+2]-128) + 4096*(.[$i+1]-128) + 262144*(.[$i]-240), loop($i+4)
      elif .[$i] >= 224 then (.[$i+2]-128) + 64*(.[$i+1]-128) + 4096*(.[$i]-224), loop($i+3)
      elif .[$i] >= 192 then (.[$i+1]-128) + 64*(.[$i]-192), loop($i+2)
      else .[$i], loop($i+1)
      end;
    [loop(0)];

  # Note that URL-encoding implies percent-encoded UTF-8 octets, so we have to
  # manually reassemble these into codepoints for implode
  gsub("(?<m>(?:%[0-9a-fA-F]{2})+)"; .m | explode | bytes | codepoints | implode);
#/urldecode

# Implements sigma for vector
def sigma: (
  (add / length) as $m |
  length as $l | 
  ( . | map((. - $m ) * (. - $m )) | add / ($l - 1) | sqrt )
);

# Normalizes vector using sigma
def anorm: (
  length as $l | 
  . as $a |
  (add / length) as $m |

  if $l < 2 then
    . 
  else
    sigma as $s |
    $a | map( (.- $m) / $s )
  end
);

# Normalizes vector by using 
def onenorm: (
  ( map( abs ) | max ) as $m |
  .[] |= (. / $m)
);

# Is array significantly different from mean $b_val ? with $fuzzy
def t_score($a; $b_val; $fuzzy): (
  {} | $a |
  ($b_val | if type == "array" then (add/ length) else . end ) as $b_val |
  ($a | length | sqrt) as $a_length_sqrt |
  ($a | (add / length) ) as $a_mean |
  ($a | [ sigma , ( $fuzzy * $a_mean | abs )] | max ) as $a_sigma |
  ($a_mean - $b_val ) / ( $a_sigma / $a_length_sqrt )
);

# Is array significantly different from mean $b_val ?
def t_score($a; $b_val): (
  t_score($a; $b_val; 0.01)
);

# t_test by adding potential uncertainty if sigma is to low compared to mean 
def t_test($a ; $b_val; $fuzzy): (
  def prop($a ; $b ; $p): (
    {} |
    $a + $p * ($b - $a) 
  );

  def get_prop($a; $b; $c): (
    {} |
    if ($b - $a) == 0 then $a else ($c - $a) / ($b - $a) end
  );
  {} | $a | 
  ($b_val | if type == "array" then (add/ length) else . end ) as $b_val |
  ( t_score($a; $b_val; $fuzzy) ) as $t_score |
  ( $t_score | abs ) as $at_score |
  ($a | length) as $a_length |
[
  {"n":1,   "vals":[[0,0],[0.5,1.000],[0.6,1.376],[0.7,1.963],[0.8,3.078],[0.9,6.314],[0.95,12.71],[0.98,31.82],[0.99,63.66],[0.998,318.31],[0.999,636.62]]},
  {"n":2,   "vals":[[0,0],[0.5,0.816],[0.6,1.061],[0.7,1.386],[0.8,1.886],[0.9,2.920],[0.95,4.303],[0.98,6.965],[0.99,9.925],[0.998,22.327],[0.999,31.599]]},
  {"n":3,   "vals":[[0,0],[0.5,0.765],[0.6,0.978],[0.7,1.250],[0.8,1.638],[0.9,2.353],[0.95,3.182],[0.98,4.541],[0.99,5.841],[0.998,10.215],[0.999,12.924]]},
  {"n":4,   "vals":[[0,0],[0.5,0.741],[0.6,0.941],[0.7,1.190],[0.8,1.533],[0.9,2.132],[0.95,2.776],[0.98,3.747],[0.99,4.604],[0.998,7.1730],[0.999,8.6100]]},
  {"n":5,   "vals":[[0,0],[0.5,0.727],[0.6,0.920],[0.7,1.156],[0.8,1.476],[0.9,2.015],[0.95,2.571],[0.98,3.365],[0.99,4.032],[0.998,5.8930],[0.999,6.8690]]},
  {"n":6,   "vals":[[0,0],[0.5,0.718],[0.6,0.906],[0.7,1.134],[0.8,1.440],[0.9,1.943],[0.95,2.447],[0.98,3.143],[0.99,3.707],[0.998,5.2080],[0.999,5.9590]]},
  {"n":7,   "vals":[[0,0],[0.5,0.711],[0.6,0.896],[0.7,1.119],[0.8,1.415],[0.9,1.895],[0.95,2.365],[0.98,2.998],[0.99,3.499],[0.998,4.7850],[0.999,5.4080]]},
  {"n":8,   "vals":[[0,0],[0.5,0.706],[0.6,0.889],[0.7,1.108],[0.8,1.397],[0.9,1.860],[0.95,2.306],[0.98,2.896],[0.99,3.355],[0.998,4.5010],[0.999,5.0410]]},
  {"n":9,   "vals":[[0,0],[0.5,0.703],[0.6,0.883],[0.7,1.100],[0.8,1.383],[0.9,1.833],[0.95,2.262],[0.98,2.821],[0.99,3.250],[0.998,4.2970],[0.999,4.7810]]},
  {"n":10,  "vals":[[0,0],[0.5,0.700],[0.6,0.879],[0.7,1.093],[0.8,1.372],[0.9,1.812],[0.95,2.228],[0.98,2.764],[0.99,3.169],[0.998,4.1440],[0.999,4.5870]]},
  {"n":11,  "vals":[[0,0],[0.5,0.697],[0.6,0.876],[0.7,1.088],[0.8,1.363],[0.9,1.796],[0.95,2.201],[0.98,2.718],[0.99,3.106],[0.998,4.0250],[0.999,4.4370]]},
  {"n":12,  "vals":[[0,0],[0.5,0.695],[0.6,0.873],[0.7,1.083],[0.8,1.356],[0.9,1.782],[0.95,2.179],[0.98,2.681],[0.99,3.055],[0.998,3.9300],[0.999,4.3180]]},
  {"n":13,  "vals":[[0,0],[0.5,0.694],[0.6,0.870],[0.7,1.079],[0.8,1.350],[0.9,1.771],[0.95,2.160],[0.98,2.650],[0.99,3.012],[0.998,3.8520],[0.999,4.2210]]},
  {"n":14,  "vals":[[0,0],[0.5,0.692],[0.6,0.868],[0.7,1.076],[0.8,1.345],[0.9,1.761],[0.95,2.145],[0.98,2.624],[0.99,2.977],[0.998,3.7870],[0.999,4.1400]]},
  {"n":15,  "vals":[[0,0],[0.5,0.691],[0.6,0.866],[0.7,1.074],[0.8,1.341],[0.9,1.753],[0.95,2.131],[0.98,2.602],[0.99,2.947],[0.998,3.7330],[0.999,4.0730]]},
  {"n":16,  "vals":[[0,0],[0.5,0.690],[0.6,0.865],[0.7,1.071],[0.8,1.337],[0.9,1.746],[0.95,2.120],[0.98,2.583],[0.99,2.921],[0.998,3.6860],[0.999,4.0150]]},
  {"n":17,  "vals":[[0,0],[0.5,0.689],[0.6,0.863],[0.7,1.069],[0.8,1.333],[0.9,1.740],[0.95,2.110],[0.98,2.567],[0.99,2.898],[0.998,3.6460],[0.999,3.9650]]},
  {"n":18,  "vals":[[0,0],[0.5,0.688],[0.6,0.862],[0.7,1.067],[0.8,1.330],[0.9,1.734],[0.95,2.101],[0.98,2.552],[0.99,2.878],[0.998,3.6100],[0.999,3.9220]]},
  {"n":19,  "vals":[[0,0],[0.5,0.688],[0.6,0.861],[0.7,1.066],[0.8,1.328],[0.9,1.729],[0.95,2.093],[0.98,2.539],[0.99,2.861],[0.998,3.5790],[0.999,3.8830]]},
  {"n":20,  "vals":[[0,0],[0.5,0.687],[0.6,0.860],[0.7,1.064],[0.8,1.325],[0.9,1.725],[0.95,2.086],[0.98,2.528],[0.99,2.845],[0.998,3.5520],[0.999,3.8500]]},
  {"n":21,  "vals":[[0,0],[0.5,0.686],[0.6,0.859],[0.7,1.063],[0.8,1.323],[0.9,1.721],[0.95,2.080],[0.98,2.518],[0.99,2.831],[0.998,3.5270],[0.999,3.8190]]},
  {"n":22,  "vals":[[0,0],[0.5,0.686],[0.6,0.858],[0.7,1.061],[0.8,1.321],[0.9,1.717],[0.95,2.074],[0.98,2.508],[0.99,2.819],[0.998,3.5050],[0.999,3.7920]]},
  {"n":23,  "vals":[[0,0],[0.5,0.685],[0.6,0.858],[0.7,1.060],[0.8,1.319],[0.9,1.714],[0.95,2.069],[0.98,2.500],[0.99,2.807],[0.998,3.4850],[0.999,3.7680]]},
  {"n":24,  "vals":[[0,0],[0.5,0.685],[0.6,0.857],[0.7,1.059],[0.8,1.318],[0.9,1.711],[0.95,2.064],[0.98,2.492],[0.99,2.797],[0.998,3.4670],[0.999,3.7450]]},
  {"n":25,  "vals":[[0,0],[0.5,0.684],[0.6,0.856],[0.7,1.058],[0.8,1.316],[0.9,1.708],[0.95,2.060],[0.98,2.485],[0.99,2.787],[0.998,3.4500],[0.999,3.7250]]},
  {"n":26,  "vals":[[0,0],[0.5,0.684],[0.6,0.856],[0.7,1.058],[0.8,1.315],[0.9,1.706],[0.95,2.056],[0.98,2.479],[0.99,2.779],[0.998,3.4500],[0.999,3.7250]]},
  {"n":27,  "vals":[[0,0],[0.5,0.684],[0.6,0.856],[0.7,1.058],[0.8,1.315],[0.9,1.706],[0.95,2.056],[0.98,2.479],[0.99,2.779],[0.998,3.4210],[0.999,3.6900]]},
  {"n":28,  "vals":[[0,0],[0.5,0.683],[0.6,0.855],[0.7,1.056],[0.8,1.313],[0.9,1.701],[0.95,2.048],[0.98,2.467],[0.99,2.763],[0.998,3.4080],[0.999,3.6740]]},
  {"n":29,  "vals":[[0,0],[0.5,0.683],[0.6,0.854],[0.7,1.055],[0.8,1.311],[0.9,1.699],[0.95,2.045],[0.98,2.462],[0.99,2.756],[0.998,3.3960],[0.999,3.6590]]},
  {"n":30,  "vals":[[0,0],[0.5,0.683],[0.6,0.854],[0.7,1.055],[0.8,1.310],[0.9,1.697],[0.95,2.042],[0.98,2.457],[0.99,2.750],[0.998,3.3850],[0.999,3.6460]]},
  {"n":40,  "vals":[[0,0],[0.5,0.681],[0.6,0.851],[0.7,1.050],[0.8,1.303],[0.9,1.684],[0.95,2.021],[0.98,2.423],[0.99,2.704],[0.998,3.3070],[0.999,3.5510]]},
  {"n":60,  "vals":[[0,0],[0.5,0.679],[0.6,0.848],[0.7,1.045],[0.8,1.296],[0.9,1.671],[0.95,2.000],[0.98,2.390],[0.99,2.660],[0.998,3.2320],[0.999,3.4600]]},
  {"n":80,  "vals":[[0,0],[0.5,0.678],[0.6,0.846],[0.7,1.043],[0.8,1.292],[0.9,1.664],[0.95,1.990],[0.98,2.374],[0.99,2.639],[0.998,3.1950],[0.999,3.4160]]},
  {"n":100, "vals":[[0,0],[0.5,0.677],[0.6,0.845],[0.7,1.042],[0.8,1.290],[0.9,1.660],[0.95,1.984],[0.98,2.364],[0.99,2.626],[0.998,3.1740],[0.999,3.3900]]},
  {"n":1000,"vals":[[0,0],[0.5,0.675],[0.6,0.842],[0.7,1.037],[0.8,1.282],[0.9,1.646],[0.95,1.962],[0.98,2.330],[0.99,2.581],[0.998,3.0980],[0.999,3.3000]]}
] as $t_table |
  $t_table | [ ( [ .[] | select(.n <= $a_length) ][-1] ) , ( [ .[] | select(.n > $a_length) ][0] ) ] as [$o, $p] |
  [$o , $p] | if (.[0].n == $a_length or (.[1] | not) )then $o else (
    get_prop(.[0].n; .[1].n; $a_length) as $prop |
    {
      n: $a_length, 
      vals: ( [ [ $o.vals[][1] ] , [  $p.vals[][1] ] ] | transpose | map(prop(.[0];.[1]; $prop))) | [ [ $o.vals[][0] ], . ] | transpose
    }
  ) end | 
  .vals | [ [ .[] | select(.[1] <= $at_score) ][-1] , [ .[] | select(.[1] > $at_score) ][0] ] | if .[0][1] == $at_score or ( .[1] | not ) then .[0][0] else
    get_prop(.[0][1]; .[1][1]; $at_score ) as $prop |
    prop(.[0][0]; .[1][0]; $prop )
  end | {
    confidence: .,
    tscore: $t_score ,
    len: $a_length,
    a_mean: ($a | (add / length)),
    a_sigma: ($a | sigma),
    corrected_sigma: ($a | [ sigma , ( $fuzzy * ($a | (add / length)) | abs )] | max ),
    b_val: ($b_val)
  }
);

# t_test by adding potential uncertainty if sigma is to low compared to mean
def t_test($a ; $b_val): (
  t_test($a; $b_val; 0.01)
);

# Flattens deep objects as mutliple objects with flattened key names
def flatten_objects:
  def f:
    if type == "array" then
      .[] | f
    elif type == "object" then
      [
        to_entries[] | {key, value: (.value | f)}
      ] | group_by(.key) | combinations | from_entries
    else
      .
    end 
  ;
  f | [ [ paths(. == false or scalars) | join(".") ] , [( .. | scalars )] ] | transpose | [ .[] | {(.[0]): (.[1])} ] | add
;

# Outputs an array of objects as a csv
# The keys should be in the same order across the array
def to_csv:
  ( [ .[0] | keys_unsorted ] ) + ( [ .[] | [ .[] ] ] ) | .[] | @csv
;

# Adds the necessary equals signs to a base64 string
def to_4eq: (
  ( [0, 0, 2, 1 ] as $a | $a[ length %4 ] ) as $l | 
  . + ( [ range($l) | "=" ] | add )
);

# Decodes a JWT token
def jwtDecode: (
  . / "." | map(to_4eq| @base64d ? | fromjson)
);
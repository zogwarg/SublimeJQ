# SYNTAX TEST "JQ.sublime-syntax"

import "test"; # with a comment
# <- keyword.control.import.jq
#      ^ punctuation.definition.string.begin.jq
#      ^^^^^^ string.quoted.double.jq
#           ^ punctuation.definition.string.end.jq
#              ^ punctuation.definition.comment.jq
#              ^^^^^^^^^^^^^^^^ comment.line.jq
# ^^^^^^^^^^^ meta.import.statement.jq

{
# <- meta.block.in_brace.jq

    brace: "value",
#   ^^^^^ entity.name.other.key.jq - meta.block.in_brace.value.jq
#        ^ punctuation.separator.mapping.key-value.jq
#          ^^^^^^^ meta.block.in_brace.value.jq string.quoted.double
#                 ^ punctuation.separator.sequence.jq

    (keys | .[3]): "haha",
#    ^^^^ support.function.builtin.jq
#   ^^^^^^^^^^^^^ - meta.block.in_brace.value.jq
#                ^ punctuation.separator.mapping.key-value.jq
#                  ^^^^^^ meta.block.in_brace.value.jq string.quoted.double
#                        ^ punctuation.separator.sequence.jq

    "why": because,
#   ^^^^^ string.quoted.double
#        ^ punctuation.separator.mapping.key-value.jq
#          ^^^^^^^ meta.block.in_brace.value.jq - entity.name.other.key.jq
#                 ^ punctuation.separator.sequence.jq
    further: {
#            ^ meta.block.in_brace.jq meta.block.in_brace.jq
#   ^^^^^^^ entity.name.other.key.jq

        random: 12
#               ^^ constant.numeric.jq
#               ^^ meta.block.in_brace.jq meta.block.in_brace.jq
#               ^^ meta.block.in_brace.value.jq meta.block.in_brace.value.jq
    }
}

def keys($value; $value; test):
# <- meta.function.jq keyword.other.function_def.jq
#   ^^^^ entity.name.function.jq - support.function.builtin.jq
#       ^ meta.function.parameters.begin.jq
#        ^^^^^^^^^^^^^^ meta.function.parameters.list.jq
#        ^^^^^^ variable.parameter.jq
#              ^ - variable.parameter.jq
#                ^^^^^^ variable.parameter.jq
#                      ^ - variable.parameter.jq
#                        ^^^^ variable.parameter.jq
#                            ^ meta.function.parameters.end.jq
#                             ^ punctuation.separator.function_def.jq

    12
;

{ array: [1, 2, 3 ,4] } | @json "My string with eval: \( .array | ( . | . += 1 ) )"
# <- meta.block.in_brace.jq -  meta.block.in_brace.jq meta.block.in_brace.jq
#        ^ meta.block.in_bracket.jq
#                    ^ - meta.block.in_bracket.jq
#                         ^^^^^ constant.language.format.jq
#                               ^^^^^^^^^^^^^^^^^^^^^^ source.jq string.quoted.double.jq
#                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ - source.jq string.quoted.double.jq
#                                                                                 ^ source.jq string.quoted.double.jq
#                                                     ^^ constant.character.escape.begin_interp.jq
#                                                                                ^ constant.character.escape.end_interp.jq
#                                                                 ^^^^^^^^^^^^^^ meta.block.parenthesis.jq


{i:0} | while(.i < 10 ; .i += 1)
#       ^^^^^ keyword.control.flow.jq

{i:0} | until(.i == 10 ; .i += 1)
#       ^^^^^ keyword.control.flow.jq
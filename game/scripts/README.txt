Flares Syntax:
    * No functions.
    * No inline operations.
    * No classes.
    * No structures.

Also, comments are defined using '#' character.

==> Operations you can do:
    * Flares operations:
    label       <label_name>:           defines a label with <label_name>
    goto        <label_name>:           go to the indicated <label_name>
    define      <variable>, <value>:    makes a new <variable> with <value>
    call        <label_name>:           go to a <label_name> but save the last location.
    return      :                       return to the most recent location.
    push        <value>:                push some value to stack.
    pop         <destination>:          pop the value to <destination>
    add         <n1>, <n2>, <result>:   result is <n1> + <n2>
    sub         <n1>, <n2>, <result>:   result is <n1> - <n2>
    mul         <n1>, <n2>, <result>:   result is <n1> * <n2>
    div         <n1>, <n2>, <result>:   result is <n1> / <n2>
    compare     <value_1>, <value_2>:   compare for equal and greater (case number)
    calleq/gotoeq   <label_name>:       in case the last compare was equal, goto or call <label_name>
    callneq/gotoneq <label_name>:       in case the last compare NOT was equal, goto or call <label_name>
    callgt/gotogt   <label_name>:       in case the last compare was greater, goto or call <label_name>
    callle/gotole   <label_name>:       in case the last compare was less, goto or call <label_name>
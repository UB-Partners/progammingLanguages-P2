load 'stdlib.ring'

func PrintGrammar()
    see "<program> -> 'wake' <keys> 'sleep' " + nl
    see "<keys> -> <key> | <key> <keys>" + nl
    see "<key> -> 'key' <letter> '=' <movement>; " + nl
    see "<letter> -> 'a' | 'b' | 'c' | 'd' " + nl
    see "<movement> -> 'DRIVE' | 'BACK' | 'LEFT' | 'RIGHT' | 'SPINL' | 'SPINR' " + nl + nl
end

# Tokenizer function to split input into tokens and find invalid inputs.
# Saves the tokens in the following order for easier access: Type: wake, Value: wake, Position: 1
Func tokenize(input)
    tokens = []
    position = 1
    words = split(input, " ")
    for word in words
        if right(word, 1) = ";"
            value = left(word, len(word) - 1)
            add(tokens, [:value = value, :position = position, :type = getTokenType(value)])
            position++
            add(tokens, [:value = ";", :position = position, :type = ";"])
        else
            add(tokens, [:value = word, :position = position, :type = getTokenType(word)])
        ok
        position++
    next
    return tokens


# Helper function to determine token type
Func getTokenType(word)
    if word = "wake" or word = "sleep" or word = "key" or word = "=" or word = ";"
        return word
    elseif word = "a" or word = "b" or word = "c" or word = "d"
        return "letter"
    elseif word = "DRIVE" or word = "BACK" or word = "LEFT" or word = "RIGHT" or word = "SPINL" or word = "SPINR"
        return "movement"
    else
        return "unknown"
    ok

Func rightmostDerivation(tokens)
    derivation = ["<program>"]
    errors = []
    
    if tokens[1][:value] != "wake"
        add(errors, "Sentence must start with 'wake'")
        return [derivation, errors]
    ok
    
    if tokens[len(tokens)][:value] != "sleep"
        add(errors, "Sentence must end with 'sleep'")
        return [derivation, errors]
    ok

    if len(tokens) <= 2
        add(errors, "Sentence must have keys between 'wake' and 'sleep'")
        return [derivation, errors]
    ok
    
    add(derivation, "wake <keys> sleep")
    
    keyCount = 0
    for i = 2 to len(tokens) - 1
        if tokens[i][:value] = "key"
            keyCount++
        ok
    next
    
    if keyCount = 0
        add(errors, "Missing 'key' keyword")
        return [derivation, errors]
    ok
    
    for i = 1 to keyCount - 1
        add(derivation, replaceRightmost(derivation[len(derivation)], "<keys>", "<key> <keys>"))
    next
    add(derivation, replaceRightmost(derivation[len(derivation)], "<keys>", "<key>"))
    
    for i = keyCount to 1 step -1
        keyIndex = 2 + (i - 1) * 5
        currentStep = derivation[len(derivation)]

        if keyIndex >= len(tokens) or tokens[keyIndex][:value] != "key"
   	 add(errors, "Missing 'key' keyword at position " + keyIndex)
    	continue  # to skip this step kinda
	ok

        if keyIndex + 1 >= len(tokens) or tokens[keyIndex + 1][:type] != "letter"
            add(errors, "Invalid letter '" + tokens[keyIndex + 1][:value] + "' at position " + (keyIndex + 1))
            return [derivation, errors]
        ok

        if keyIndex + 2 >= len(tokens) or tokens[keyIndex + 2][:value] != "="
            add(errors, "Missing '=' sign at position " + (keyIndex + 2))
            return [derivation, errors]
        ok

        if keyIndex + 3 >= len(tokens) or tokens[keyIndex + 3][:type] != "movement"
            add(errors, "Invalid movement '" + tokens[keyIndex + 3][:value] + "' at position " + (keyIndex + 3))
            return [derivation, errors]
        ok

       if keyIndex + 4 >= len(tokens) or tokens[keyIndex + 4][:value] != ";"
    add(errors, "Missing ';' after " + tokens[keyIndex + 3][:value] + " at position " + (keyIndex + 4))
    continue  # Change return to continue to allow further processing
ok
        newStep = replaceRightmost(currentStep, "<key>", "key <letter> = <movement>;")
        add(derivation, newStep)
        
        newStep = replaceRightmost(newStep, "<movement>", tokens[keyIndex + 3][:value])
        add(derivation, newStep)
        
        newStep = replaceRightmost(newStep, "<letter>", tokens[keyIndex + 1][:value])
        add(derivation, newStep)
    next

    return [derivation, errors]
end





# Helper function to replace the rightmost occurrence of a substring
Func replaceRightmost(str, oldSubStr, newSubStr)
    pos = rightStrPos(str, oldSubStr)
    if pos = 0
        return str
    ok
    return left(str, pos - 1) + newSubStr + substr(str, pos + len(oldSubStr))

# Helper function to find the position of the rightmost occurrence of a substring
Func rightStrPos(str, subStr)
    lenStr = len(str)
    lenSubStr = len(subStr)
    for i = lenStr - lenSubStr + 1 to 1 step -1
        if substr(str, i, lenSubStr) = subStr
            return i
        ok
    next
    return 0

func main()
    see "This is the grammar" + nl + nl
    PrintGrammar()

    # List of test cases you can try adding more to it just to make sure it works
    testCases = [
        "wake key a = RIGHT; key b = DRIVE; sleep",
        "wake key a = RIGHT key b = DRIVE; sleep",
        "wake key a = DRIVE sleep",
        "wake key e = DRIVE; sleep",
        "wake sleep",
        "wake key a = FLY; sleep",
        "wake key a DRIVE; sleep",
        "wake key = DRIVE; sleep",
        "wake key a = ; sleep",
        "wake a = DRIVE; sleep",
        "wake key a = RIGHT; key b = LEFT sleep",
        "wake key a = RIGHT; key b = LEFT; key c = DRIVE; sleep",
        "wake key a = RIGHT; key b = LEFT key c = DRIVE; sleep",
        "wake key a = RIGHT; key b sleep",
        "wake key a = RIGHT; key = LEFT; sleep"
    ]

    # Process each test case
    for testCase in testCases
        see nl + "Testing: " + testCase + nl
        tokens = tokenize(testCase)

        see nl + "Rightmost Derivation:" + nl
        result = rightmostDerivation(tokens)
        derivation = result[1]
        errors = result[2]

        # Print the derivation
        for derstep in derivation
            see derstep + nl
        next
	
       if len(errors) > 0
    see nl + "Errors:" + nl
    if len(errors) > 1
        see "- " + errors[2] + nl
    else
        see "- " + errors[1] + nl
    ok
else
    see nl + "Sentence was parsed successfully." + nl
ok
        see nl + "----------------------------------------" + nl
    next
end

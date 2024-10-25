load 'stdlib.ring'

func PrintGrammar()
    see "<program> -> 'wake' <keys> 'sleep' " + nl
    see "<keys> -> <key> | <key> <keys>" + nl
    see "<key> -> 'key' <letter> '=' <movement>; " + nl
    see "<letter> -> 'a' | 'b' | 'c' | 'd' " + nl
    see "<movement> -> 'DRIVE' | 'BACK' | 'LEFT' | 'RIGHT' | 'SPINL' | 'SPINR' " + nl + nl
end

# Tokenizer function remains the same
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

# Helper function remains the same
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

Func leftmostDerivation(tokens)
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

    add(derivation, "-> wake <keys> sleep")

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

    # First expand all <keys> from left to right
    for i = 1 to keyCount - 1
        add(derivation, replaceLeftmost(derivation[len(derivation)], "<keys>", "<key> <keys>"))
    next
    add(derivation, replaceLeftmost(derivation[len(derivation)], "<keys>", "<key>"))

    # Then expand each <key> from left to right
    currentKeyIndex = 2  # Start after 'wake'
    for i = 1 to keyCount
        currentStep = derivation[len(derivation)]
        
        if currentKeyIndex >= len(tokens) or tokens[currentKeyIndex][:value] != "key"
            add(errors, "Missing 'key' keyword at position " + currentKeyIndex)
            return [derivation, errors]
        ok

        if currentKeyIndex + 1 >= len(tokens) or tokens[currentKeyIndex + 1][:type] != "letter"
            add(errors, "Invalid letter '" + tokens[currentKeyIndex + 1][:value] + "' at position " + (currentKeyIndex + 1))
            return [derivation, errors]
        ok

        if currentKeyIndex + 2 >= len(tokens) or tokens[currentKeyIndex + 2][:value] != "="
            add(errors, "Missing '=' sign at position " + (currentKeyIndex + 2))
            return [derivation, errors]
        ok

        if currentKeyIndex + 3 >= len(tokens) or tokens[currentKeyIndex + 3][:type] != "movement"
            add(errors, "Invalid movement '" + tokens[currentKeyIndex + 3][:value] + "' at position " + (currentKeyIndex + 3))
            return [derivation, errors]
        ok

        if currentKeyIndex + 4 >= len(tokens) or tokens[currentKeyIndex + 4][:value] != ";"
            add(errors, "Missing ';' after " + tokens[currentKeyIndex + 3][:value] + " at position " + (currentKeyIndex + 4))
            return [derivation, errors]
        ok

        # Check if the next token after semicolon is a letter without a 'key' keyword
        if currentKeyIndex + 5 < len(tokens) - 1 and  # Ensure we're not at 'sleep'
           tokens[currentKeyIndex + 5][:type] = "letter"
            add(errors, "Missing 'key' keyword after ';' at position " + (currentKeyIndex + 4))
	    return [derivation, errors]
        ok

        # Expand <key> in leftmost order
        newStep = replaceLeftmost(currentStep, "<key>", "key <letter> = <movement>;")
        add(derivation, newStep)
        
        # Expand <letter> immediately after
        newStep = replaceLeftmost(newStep, "<letter>", tokens[currentKeyIndex + 1][:value])
        add(derivation, newStep)
        
        # Finally expand <movement>
        newStep = replaceLeftmost(newStep, "<movement>", tokens[currentKeyIndex + 3][:value])
        add(derivation, newStep)

        currentKeyIndex += 5  # Move to next key section
    next

    return [derivation, errors]
end

# Helper function to find the position of the leftmost occurrence of a substring
Func leftStrPos(str, subStr)
    lenStr = len(str)
    lenSubStr = len(subStr)
    for i = 1 to lenStr - lenSubStr + 1
        if substr(str, i, lenSubStr) = subStr
            return i
        ok
    next
    return 0

# Helper function to replace the leftmost occurrence of a substring
Func replaceLeftmost(str, oldSubStr, newSubStr)
    pos = leftStrPos(str, oldSubStr)
    if pos = 0
        return str
    ok
    return left(str, pos - 1) + newSubStr + substr(str, pos + len(oldSubStr))

# Add this function to check for duplicate keys
func checkDuplicateKeys(tokens)
    keys = []
    errors = []
    for i = 1 to len(tokens)
        if tokens[i][:type] = "letter"
            if find(keys, tokens[i][:value]) > 0
                add(errors, "IMPORTANT!: Key '" + tokens[i][:value] + "' has been declared more than once.")
            else
                add(keys, tokens[i][:value])
            ok
        ok
    next
    return errors
end

# Modified print parse tree function
func printParseTree(tokens)
    see nl + "-----------------------------------------------------------" + nl
    see "PARSE TREE: " + nl + nl
    
    # First check for duplicate keys
    duplicateErrors = checkDuplicateKeys(tokens)
    if len(duplicateErrors) > 0
        for error in duplicateErrors
            see error + nl
        next
        see nl + "Would you like to continue viewing the parse tree? (Y/N): " give choice
        if choice != "y"
            return
        ok
    ok
    
    # Count number of key statements
    keyCount = 0
    for token in tokens
        if token[:value] = "key"
            keyCount++
        ok
    next
    
    # Check if number of keys exceeds limit
    if keyCount > 4
        see "Error: More than 4 keys detected. Only a, b, c, and d are allowed." + nl
        return
    ok
    
    # Get the key and action parts for each key statement
    keyParts = []
    actionParts = []
    i = 2  # Start after 'wake'
    while i < len(tokens) - 1  # Stop before 'sleep'
        if tokens[i][:value] = "key"
            add(keyParts, tokens[i+1][:value])  # Letter after 'key'
            add(actionParts, tokens[i+3][:value])  # Action after '='
        ok
        i++
    end
 
    
    if keyCount = 1
        see "                    <program>" + nl
        see "                        |" + nl
        see "                 wake <keys> sleep" + nl
        see "                        |" + nl
        see "                      <key>"   + nl                
	see "                   _____|____"  + nl                  
        see "                  /          \" + nl                   
        see "           key <key>  =  <movement> ;" + nl          
        see "                 |            |" + nl        
        see "                 " + keyParts[1] + "           " + actionParts[1] + nl
    ok
    if keyCount = 2
        see "                         <program>" + nl
        see "                             |" + nl
        see "                     wake <keys> sleep" + nl
	see "                 ____________|____________" +nl
        see "                /                         \" + nl
        see "             <key>                      <keys>" + nl
	see "           ____|_____                      |" +nl
        see "          /          \                     |" + nl
        see "   key <key>  =  <movement> ;              | " + nl
        see "         |            |                    |" + nl
        see "         " + keyParts[1] + "       <movement>                |" + nl                               
        see "                      |                    |" + nl
        see "                    "+ actionParts[1] +"                <key>" + nl
	see "                                       ____|_____" +nl
        see "                                      /          \" + nl
        see "                               key <key>  =  <movement> ;" + nl
	see "                                     |            |" + nl
        see "                                     "+ keyParts[2] + "        <movement>" + nl
	see "                                                  |" + nl
	see "                                                 "+ actionParts[2] + nl 
    ok

    see nl + "Parse Tree Printed successfully" + nl
    writeToFile(tokens)  # Pass tokens to writeToFile
end

func writeToFile(tokens)
    # Open file for writing
    fp = fopen("iZEBot.bas", "w")
    
    # Write exact format with no extra newlines or spacing
    code = "'{$STAMP BS2p}" + nl
    code += "'{$PBASIC 2.5}" + nl
    code += "KEY VAR Byte" + nl
    code += "Main:" + nl
    code += "DO" + nl
    code += "SERIN 3,2063,250,Timeout,[KEY]" + nl
    
    # Generate IF statements for each key assignment
    currentKeyIndex = 2  # Start after 'wake'
    while currentKeyIndex < len(tokens) - 1  # Stop before 'sleep'
        if tokens[currentKeyIndex][:value] = "key"
            letter = tokens[currentKeyIndex + 1][:value]
            movement = tokens[currentKeyIndex + 3][:value]
            
            # Convert movement names to subroutine names
            switch movement
                on "DRIVE"
                    routine = "Forward"
                on "BACK"
                    routine = "Backward"
                on "LEFT"
                    routine = "TurnLeft"
                on "RIGHT"
                    routine = "TurnRight"
                on "SPINL"
                    routine = "SpinLeft"
                on "SPINR"
                    routine = "SpinRight"
            off
            
            # Generate IF statement matching exact format
            code += "IF KEY =  '"+ upper(letter) +"' OR KEY = '"+ lower(letter)
            code += "' THEN GOSUB " + routine + nl
        ok
        currentKeyIndex += 5
    end
    
    code += "LOOP" + nl
    code += "Timeout:" + nl
    code += "GOSUB Motor_OFF" + nl
    code += "GOTO Main" + nl
    code += "'+++++ Movement Procedure +++++++++++++++++++++++++++++" + nl
    code += "Forward:" + nl
    code += "HIGH 13 : LOW 12 : HIGH 15 : LOW 14 : RETURN" + nl
    code += "Backward:" + nl
    code += "HIGH 12 : LOW 13 : HIGH 14 : LOW 15 : RETURN" + nl
    code += "TurnLeft:" + nl
    code += "HIGH 13 : LOW 12 : LOW 15 : LOW 14 : RETURN" + nl
    code += "TurnRight:" + nl
    code += "LOW 13 : LOW 12 : HIGH 15 : LOW 14 : RETURN" + nl
    code += "SpinLeft:" + nl
    code += "HIGH 13 : LOW 12 : HIGH 14 : LOW 15 : RETURN" + nl
    code += "SpinRight:" + nl
    code += "HIGH 12 : LOW 13 : HIGH 15 : LOW 14 : RETURN" + nl
    code += "Motor_OFF:" + nl
    code += "LOW 13 : LOW 12 : LOW 15 : LOW 14 : RETURN" + nl
    code += "'++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + nl

    # Write the content to file
    fwrite(fp, code)

    # Close the file
    fclose(fp)

    # Verify file was written
    if fexists("iZEBot.bas")
        see nl + "-----------------------------------------------------------" + nl
        see "File 'iZEBot.bas' has been created successfully!"
        see nl + "-----------------------------------------------------------" + nl
    else
        see "Error creating file"
    ok
end

Func continueOrHalt()
    see "Press any key to continue or type 'HALT'/'halt' to terminate: " give userInput

    if userInput = "HALT" or userInput = "halt"
        see "Program terminated." + nl
        bye
    else
        see "Restarting the program..." + nl
	see nl + "-----------------------------------------------------------" + nl
        main()
    ok
end

func main()
    see "This is the grammar" + nl + nl
    PrintGrammar()

    see nl + "-----------------------------------------------------------" + nl
    see "Please Enter a Sentence: " + nl give sentence
    tokens = tokenize(sentence)

    see "Derivation:" + nl
    result = leftmostDerivation(tokens)
    derivation = result[1]
    errors = result[2]

    # Print the derivation
    for derstep in derivation
        see derstep + nl
    next

    if len(errors) > 0
        see nl + "Error:"
        for i = 1 to len(errors)
            see "- " + errors[i] + nl
        next
        continueOrHalt()
    else
        see nl + "Sentence was parsed successfully." + nl
	see nl + "-----------------------------------------------------------" + nl 
        see "Press any key to print the parse tree or type 'HALT'/'halt' to terminate: " give userInput
        if userInput = "HALT" or userInput = "halt"
            see "Program terminated." + nl
            bye
        else
            printParseTree(tokens)
            see nl + "Press any key to restart or type 'HALT'/'halt' to terminate: " give userInput
            if userInput = "HALT" or userInput = "halt"
                see "Program terminated." + nl
                bye
            else
	 	see nl + "-----------------------------------------------------------" + nl
                see nl + "Restarting..." + nl
                main()
            ok
        ok
    ok
end

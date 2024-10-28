 load 'stdlib.ring'

func PrintGrammar() # Prints the grammar
    see "<program> -> 'wake' <keys> 'sleep' " + nl
    see "<keys> -> <key> | <key> <keys>" + nl
    see "<key> -> 'key' <letter> '=' <movement>; " + nl
    see "<letter> -> 'a' | 'b' | 'c' | 'd' " + nl
    see "<movement> -> 'DRIVE' | 'BACK' | 'LEFT' | 'RIGHT' | 'SPINL' | 'SPINR' " + nl + nl
end

# Splits the sentence into tokens; returns it in a map function by value, position, and type
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

# Checks to see which token type it is
Func getTokenType(word)
    if word = "wake" or word = "sleep" or word = "key" or word = "=" or word = ";"
        return word
    elseif word = "a" or word = "b" or word = "c" or word = "d"
        return "letter"
    elseif word = "DRIVE" or word = "BACK" or word = "LEFT" or word = "RIGHT" or word = "SPINL" or word = "SPINR"
        return "movement"
    else
        # Check if it might be an invalid letter or movement
        validLetters = ["a", "b", "c", "d"]
        validMovements = ["DRIVE", "BACK", "LEFT", "RIGHT", "SPINL", "SPINR"]
        
        if len(word) = 1 and isalpha(word)  # Looks like it was meant to be a letter
            if find(validLetters, lower(word)) = 0
                return "invalid_letter"
            ok
        ok
        
        if upper(word) = word  # All caps - might be meant as a movement
            if find(validMovements, word) = 0
                return "invalid_movement"
            ok
        ok
        
        return "unknown"  # Completely unknown type
    ok

# Performs the leftmost derivation.
Func leftmostDerivation(tokens)
    derivation = ["<program>"]
    errors = []

    # Check first and last tokens
    if tokens[1][:type] = "unknown"
        add(errors, "Invalid word '" + tokens[1][:value] + "' at position 1. Expected 'wake'")
        return [derivation, errors]
    elseif tokens[1][:value] != "wake"
        add(errors, "Sentence must start with 'wake'")
        return [derivation, errors]
    ok

    if tokens[len(tokens)][:type] = "unknown"
        add(errors, "Invalid word '" + tokens[len(tokens)][:value] + "' at position " + len(tokens) + ". Expected 'sleep'")
        return [derivation, errors]
    elseif tokens[len(tokens)][:value] != "sleep"
        add(errors, "Sentence must end with 'sleep'")
        return [derivation, errors]
    ok

    if len(tokens) <= 2
        add(errors, "Sentence must have at least 1 key between 'wake' and 'sleep'")
        return [derivation, errors]
    ok

    # Count keys to help with derivation steps
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

    # Start the derivation
    add(derivation, "-> wake <keys> sleep")
    
    if keyCount = 1
        add(derivation, "-> wake <key> sleep")
    else
        add(derivation, "-> wake <key> <keys> sleep")
    ok

    currentKeyIndex = 2  # Start after 'wake'
    processedKeys = 0

    while currentKeyIndex < len(tokens) - 1  # Stop before 'sleep'
        if tokens[currentKeyIndex][:value] = "key"
            # Check letter
            if currentKeyIndex + 1 >= len(tokens)
                add(errors, "Missing letter after 'key' at position " + (currentKeyIndex + 1))
                return [derivation, errors]
            ok
            
            letterToken = tokens[currentKeyIndex + 1]
            if letterToken[:type] = "invalid_letter"
                add(errors, "Invalid letter '" + letterToken[:value] + "' at position " + (currentKeyIndex + 1) + ". Valid letters are: a, b, c, d")
                return [derivation, errors]
            elseif letterToken[:type] != "letter"
                add(errors, "Invalid word '" + letterToken[:value] + "' at position " + (currentKeyIndex + 1) + ". Expected a letter (a, b, c, or d)")
                return [derivation, errors]
            ok

            # Check equals sign
            if currentKeyIndex + 2 >= len(tokens)
                add(errors, "Missing '=' sign at position " + (currentKeyIndex + 2))
                return [derivation, errors]
            ok
            
            if tokens[currentKeyIndex + 2][:value] != "="
                add(errors, "Invalid word '" + tokens[currentKeyIndex + 2][:value] + "' at position " + (currentKeyIndex + 2) + ". Expected '='")
                return [derivation, errors]
            ok

            # Check movement
            if currentKeyIndex + 3 >= len(tokens)
                add(errors, "Missing movement at position " + (currentKeyIndex + 3))
                return [derivation, errors]
            ok
            
            movementToken = tokens[currentKeyIndex + 3]
            if movementToken[:type] = "invalid_movement"
                add(errors, "Invalid movement '" + movementToken[:value] + "' at position " + (currentKeyIndex + 3) + ". Valid movements are: DRIVE, BACK, LEFT, RIGHT, SPINL, SPINR")
                return [derivation, errors]
            elseif movementToken[:type] != "movement"
                add(errors, "Invalid word '" + movementToken[:value] + "' at position " + (currentKeyIndex + 3) + ". Expected a movement (DRIVE, BACK, LEFT, RIGHT, SPINL, SPINR)")
                return [derivation, errors]
            ok

            # Check semicolon
            if currentKeyIndex + 4 >= len(tokens)
                add(errors, "Missing ';' after movement at position " + (currentKeyIndex + 4))
                return [derivation, errors]
            ok
            
            if tokens[currentKeyIndex + 4][:value] != ";"
                add(errors, "Invalid word '" + tokens[currentKeyIndex + 4][:value] + "' at position " + (currentKeyIndex + 4) + ". Expected ';'")
                return [derivation, errors]
            ok

            # Rest of the derivation steps remain the same...
            processedKeys++
            currentStep = derivation[len(derivation)]
            
            if keyCount = 1
		# One key
                add(derivation, "-> wake key <letter> = <movement>; sleep")
                add(derivation, "-> wake key " + tokens[currentKeyIndex + 1][:value] + " = <movement>; sleep")
                add(derivation, "-> wake key " + tokens[currentKeyIndex + 1][:value] + " = " + tokens[currentKeyIndex + 3][:value] + "; sleep")
            else
                if processedKeys = 1
		    # First key
                    add(derivation, "-> wake key <letter> = <movement>; <keys> sleep")
                    add(derivation, "-> wake key " + tokens[currentKeyIndex + 1][:value] + " = <movement>; <keys> sleep")
                    add(derivation, "-> wake key " + tokens[currentKeyIndex + 1][:value] + " = " + tokens[currentKeyIndex + 3][:value] + "; <keys> sleep")
                else
                    if processedKeys < keyCount
                        add(derivation, replaceLeftmost(currentStep, "<keys>", "<key> <keys>"))
                        add(derivation, replaceLeftmost(derivation[len(derivation)], "<key>", "key <letter> = <movement>;"))
                        add(derivation, replaceLeftmost(derivation[len(derivation)], "<letter>", tokens[currentKeyIndex + 1][:value]))
                        add(derivation, replaceLeftmost(derivation[len(derivation)], "<movement>", tokens[currentKeyIndex + 3][:value]))
                    else
			# Last key
                        add(derivation, replaceLeftmost(currentStep, "<keys>", "<key>"))
                        add(derivation, replaceLeftmost(derivation[len(derivation)], "<key>", "key <letter> = <movement>;"))
                        add(derivation, replaceLeftmost(derivation[len(derivation)], "<letter>", tokens[currentKeyIndex + 1][:value]))
                        add(derivation, replaceLeftmost(derivation[len(derivation)], "<movement>", tokens[currentKeyIndex + 3][:value]))
                    ok
                ok
            ok
            
            currentKeyIndex += 5
        else
            add(errors, "Expected 'key' keyword at position " + currentKeyIndex + ", got '" + tokens[currentKeyIndex][:value] + "' instead")
            return [derivation, errors]
        ok
    end

    return [derivation, errors]
end

# Finds a substring in the sentence
Func leftStrPos(str, subStr)
    lenStr = len(str)
    lenSubStr = len(subStr)
    for i = 1 to lenStr - lenSubStr + 1
        if substr(str, i, lenSubStr) = subStr
            return i
        ok
    next
    return 0

# Replace the leftmost occurrence of a substring
Func replaceLeftmost(str, oldSubStr, newSubStr)
    pos = leftStrPos(str, oldSubStr)
    if pos = 0
        return str
    ok
    return left(str, pos - 1) + newSubStr + substr(str, pos + len(oldSubStr))

# Checks for duplicate keys or re-declaration
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

# Parse tree the sentence
func printParseTree(tokens)
    see "-----------------------------------------------------------" + nl
    see "PARSE TREE: " + nl + nl
    
    # Count number of keys
    keyCount = 0
    for token in tokens
        if token[:value] = "key"
            keyCount++
        ok
    next

    # Check if there are more than 4 keys
    if keyCount > 4
        see "ERROR: More than 4 keys detected. Only single declarations of lower case or upper case a, b, c, and d are allowed." + nl
        restartOrEnd()
    ok

    # Check for duplicates if 4 keys
    if keyCount <= 4
        duplicateErrors = checkDuplicateKeys(tokens)
        if len(duplicateErrors) > 0
            for error in duplicateErrors
                see error + nl
            next
            see nl + "Would you like to continue viewing the parse tree? (Y/N): " give choice
            while choice != "Y" and choice != "N"
                see "Please enter Y or N: " give choice
            end
            if choice != "Y"
                restartOrEnd()
	    else
   	        see "-----------------------------------------------------------" + nl
	        see "PARSE TREE: " + nl + nl
            ok
        ok
    ok
    
    # Get the key and action parts for each key statement
    keyParts = []
    actionParts = []
    i = 2  # Start after 'wake'
    while i < len(tokens) - 1  # Stops before 'sleep'
        if tokens[i][:value] = "key"
            add(keyParts, tokens[i+1][:value])  # Letter after 'key' based on indexing of the map
            add(actionParts, tokens[i+3][:value])  # Action after '=' based on idexing of the map
        ok
        i++
    end
 
    # Hardcoded TREE cause why not
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
        see "                 " + keyParts[1] + "            |" + nl          
 	see "                            "+ actionParts[1] + nl
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
        see "         " + keyParts[1] + "            |                    |" + nl                               
        see "                    "+ actionParts[1] +"                  |" + nl
        see "                                         <key>" + nl
	see "                                       ____|_____" +nl
        see "                                      /          \" + nl
        see "                               key <key>  =  <movement> ;" + nl
	see "                                     |            |" + nl
        see "                                     "+ keyParts[2] + "            |" + nl
	see "                                                 "+ actionParts[2] + nl 
    ok
    if keyCount = 3
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
        see "         " + keyParts[1] + "            |                    |" + nl                               
        see "                    "+ actionParts[1] +"      ____________|____________" + nl
        see "                              /                         \" + nl
        see "                           <key>                      <keys>" + nl
	see "                         ____|_____                      |"+nl
        see "                        /          \                     |" + nl
        see "                  key <key>  =  <movement> ;             |" + nl
	see "                       |            |                    |" + nl
        see "                       "+ keyParts[2] + "            |                    |" + nl
	see "                                   "+ actionParts[2] +"                  |" + nl 
	see "                                                       <key>" + nl 
	see "                                                    _____|____"  + nl
        see "                                                   /          \" + nl 
        see "                                             key <key>  =  <movement> ;" + nl
        see "                                                  |            |" + nl    
        see "                                                  " + keyParts[3] + "            |" + nl  
	see "                                                             "+ actionParts[3] + nl 
    ok
    if keyCount = 4
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
        see "         " + keyParts[1] + "            |                    |" + nl                               
        see "                    "+ actionParts[1] +"      ____________|____________" + nl
        see "                              /                         \" + nl
        see "                           <key>                      <keys>" + nl
	see "                         ____|_____                      |"+nl
        see "                        /          \                     |" + nl
        see "                  key <key>  =  <movement> ;             |" + nl
	see "                       |            |                    |" + nl
        see "                       "+ keyParts[2] + "            |                    |" + nl
	see "                                  "+ actionParts[2] +"                  |" + nl 
	see "                                             ____________|____________" + nl 
        see "                                            /                         \" + nl
        see "                                          <key>                      <keys>" + nl
	see "                                       _____|___                       |"  + nl
        see "                                      /          \                     |" + nl 
        see "                                key <key>  =  <movement> ;             |" + nl
        see "                                     |            |                    |" + nl    
        see "                                     " + keyParts[3] + "            |                    |" + nl  
	see "                                                "+ actionParts[3] +"                  |" + nl 
        see "                                                                     <key>"   + nl                
	see "                                                                  _____|____"  + nl                  
        see "                                                                 /          \" + nl                   
        see "                                                           key <key>  =  <movement> ;" + nl          
        see "                                                                |            |" + nl        
        see "                                                                " + keyParts[4] + "            |" + nl          
 	see "                                                                            "+ actionParts[4] + nl
    ok	
	
    	see nl + "Parse Tree Printed successfully" + nl
	see nl + "-----------------------------------------------------------" + nl
end

func restartOrEnd()
	see nl + "Press any key to restart or type 'END'/'end' to terminate: " give userInput
        if userInput = "END" or userInput = "end"
            see "Program terminated." + nl
            return
        else
	    see nl + "-----------------------------------------------------------" + nl
            see nl + "Restarting..." + nl
            main() # Calls main to restart
        ok

# Writes/create a file, will overwrite on the second call
func writeToFile(tokens)
    # Open file for writing
    fp = fopen("iZEBOT.BSP", "w") # Open file to write
    
    # Write the code variable to the file following the format, adds necessary info by concatenation
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
            code += 'IF KEY = "'+ lower(letter)
            code += '" THEN GOSUB ' + routine + nl
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
    if fexists("iZEBot.BSP")
        see nl + "-----------------------------------------------------------" + nl
        see "File 'iZEBot.BSP' has been created successfully!" + nl
	see "File path is: " + currentdir() + "/iZEBot.BSP"
        see nl + "-----------------------------------------------------------" + nl
	see code + nl
    else
        see "Error creating file"
	restartOrEnd()
    ok
end

func main()
    see "This is the grammar" + nl + nl
    PrintGrammar()

    while true
        see nl + "-----------------------------------------------------------" + nl
        see "Please Enter a Sentence or 'END'/'end' to terminate: " give sentence
        
        # Check if sentence is empty or only contains whitespace
        if sentence = "" or trim(sentence) = ""
            see nl + "Empty sentence. Please try again." + nl
            loop
        ok

        if sentence = "END" or sentence = "end"
                see "Program terminated." + nl
                return
        ok

        tokens = tokenize(sentence)
        
        see nl + "Derivation:" + nl + nl
        result = leftmostDerivation(tokens)
        derivation = result[1]
        errors = result[2]

        # Print the derivation
        for derstep in derivation
            see derstep + nl
        next

        if len(errors) > 0
            see nl + "ERROR:"
            for i = 1 to len(errors)
                see " " + errors[i] + nl
            next
            restartOrEnd()
            return
        else
            see nl + "Sentence was parsed successfully." + nl
            see "-----------------------------------------------------------" + nl
            see "Press any key to print the parse tree or type 'END'/'end' to terminate: " give userInput
            if userInput = "END" or userInput = "end"
                see "Program terminated." + nl
                return
            else
                printParseTree(tokens)
		see "Press any key to generate BASIC file: " give userInput
                if userInput = "" or trim(sentence) = "" # Empty sentence check to proceed
        		writeToFile(tokens) # Creates the file
       			restartOrEnd()
		elseif userInput != "" or trim(sentence) != "" # Not empty sentence
			writeToFile(tokens) # Creates the file
       			restartOrEnd()
    		ok
            ok
        ok
        exit  # Exit the while loop if we get here
    end
end

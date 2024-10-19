load "stdlib.ring"

# Function to print grammar rules  
func PrintGrammar()
    see "<program> -> 'wake' <keys> 'sleep' " + nl
    see "<keys> -> <key> | <key> <keys>" + nl
    see "<key> -> 'key' <letter> '=' <movement>; " + nl
    see "<letter> -> 'a' | 'b' | 'c' | 'd' " + nl
    see "<movement> -> 'DRIVE' | 'BACK' | 'LEFT' | 'RIGHT' | 'SPINL' | 'SPINR' " + nl + nl
end

# Checks if a substring is in the string
func instr(s, substr)
    len_s = len(s)
    len_substr = len(substr)
	# Goes through the entire string, and extracts a substring of the lenght of substr parameter
    for i = 1 to len_s - len_substr + 1
	# Compares to see if they are the same
        if substr(s, i, len_substr) = substr
            return i
        end
    next
    return 0
end

# Custom function to find substring position, to use when deriving from right to left
# Takes a substring and finds it in the string and returns its position starting position
func findAllPositions(s, substr)
    positions = []
    len_s = len(s) # Finds the lenght of the string
    len_substr = len(substr) # Finds the lenght of the substring
    i = 1 # Ring is 1 based
    while i <= len_s - len_substr + 1
        if substr(s, i, len_substr) = substr
            add(positions, i)
            i += 1  # Move to next character after this match
        else
            i += 1
        end
    end
    return positions
end

# Tokenize input based on spaces and semicolo, basically seperates them into words 
func tokenize(input)
    input = trim(input)
    tokens = []
    word = ""
    for c in input
        if c = " " or c = ";"
            if word != ""
                add(tokens, word)
                word = ""
            end
            if c = ";"
                add(tokens, ";")
            end
        else
            word += c
        end
    next
    if word != ""
        add(tokens, word)
    end
    return tokens
end

# Should give the rightmost derivation
func RightmostDerivation(input)
    derivations = []
    error = ""

    # Split input into tokens
    tokens = tokenize(input)

    # Check start and end conditions
    if len(tokens) < 2 or tokens[1] != "wake"
        error = "Error: sentence must start with 'wake'"
    elseif tokens[len(tokens)] != "sleep"
        error = "Error: sentence must end with 'sleep'"
    else
        # Finds the indexes of 'key'
        keyTokens = []
        for i = 1 to len(tokens)
            if tokens[i] = "key"
                add(keyTokens, i)
            end
        next
	# Used to generate the correct number of <key> <keys>
        keyCount = len(keyTokens)

        see "Number of keys: " + keyCount + nl

        # Proceed if no error and at least one key
        if error = "" and keyCount > 0
            # Initial derivation step
            derivation = "<program> -> wake <keys> sleep"
            add(derivations, derivation)

            keyProcessed = 0
            keysExpanded = 0

            while true
                # Find positions of non-terminals
                positions = []
                for nt in ["<keys>", "<key>", "<letter>", "<movement>"]
                    pos_list = findAllPositions(derivation, nt)
                    for pos_nt in pos_list
                        add(positions, [pos_nt, nt])
                    next
                next

                if len(positions) = 0
                    break  # No more non-terminals
                end

                # Find the rightmost non-terminal
                maxPos = 0
                ntToReplace = ""
                for item in positions
                    if item[1] > maxPos
                        maxPos = item[1]
                        ntToReplace = item[2]
                    end
                next

                pos_nt = maxPos
                nt = ntToReplace

                if nt = "<keys>"
                    if keysExpanded < keyCount - 1
                        # Replace <keys> with <key> <keys>
                        derivation = substr(derivation, 1, pos_nt - 1) + "<key> <keys>" + substr(derivation, pos_nt + len(nt))
                        keysExpanded += 1
                    else
                        # Replace <keys> with <key>
                        derivation = substr(derivation, 1, pos_nt - 1) + "<key>" + substr(derivation, pos_nt + len(nt))
                    end
                    add(derivations, derivation)
                elseif nt = "<key>"
                    # Set tokenIndex to position of current 'key' token (reverse order for rightmost derivation)
                    tokenIndex = keyTokens[keyCount - keyProcessed]
                    # Replace <key> with 'key <letter> = <movement>;'
                    derivation = substr(derivation, 1, pos_nt - 1) + "key <letter> = <movement>;" + substr(derivation, pos_nt + len(nt))
                    add(derivations, derivation)
                    keyProcessed += 1  # Increment keyProcessed here
                elseif nt = "<letter>"
                    # Check bounds before accessing tokens
                    if tokenIndex + 1 <= len(tokens)
                        # Replace <letter> with corresponding letter from tokens
                        letterToken = tokens[tokenIndex + 1]  # tokens after 'key'
                        derivation = substr(derivation, 1, pos_nt - 1) + letterToken + substr(derivation, pos_nt + len(nt))
                        add(derivations, derivation)
                    else
                        error = "Error: Not enough tokens to process <letter> for key at position " + tokenIndex
                        break
                    end
                elseif nt = "<movement>"
                    # Check bounds before accessing tokens
                    if tokenIndex + 3 <= len(tokens)
                        # Replace <movement> with corresponding movement from tokens
                        movementToken = tokens[tokenIndex + 3]  # tokens after '='
                        derivation = substr(derivation, 1, pos_nt - 1) + movementToken + substr(derivation, pos_nt + len(nt))
                        add(derivations, derivation)
                    else
                        error = "Error: Not enough tokens to process <movement> for key at position " + tokenIndex
                        break
                    end
                end
            end
        end
    end

    return [derivations, error]
end

# Main program
func main ()
    see "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + nl + nl
    see "THIS IS THE GRAMMAR" + nl + nl
    PrintGrammar()

    see "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + nl + nl
    see "Please enter a sentence: " give sentence

    see "Tokens: " + nl
    tokens = tokenize(sentence)
    for token in tokens
        see token + nl
    next

    result = RightmostDerivation(sentence)
    derivations = result[1]
    error = result[2]

    see nl + "Derivation: " + nl
    if len(derivations) > 0
        for derivation in derivations
            see derivation + nl
        next
    end

    if error != ""
        see nl + error + nl
    end
end


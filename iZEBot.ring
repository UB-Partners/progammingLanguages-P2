load "stdlib.ring"
# main is at the bottom: look down :)

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Function to print grammar rules  
func PrintGrammar()
  	see "<program> ::= 'wake' <keys> 'sleep' " + nl
	see "<keys> ::= <key> | <key> <keys> + nl"
	see "<key> ::= 'key' <letter> '=' <movement> ';' " + nl
	see "<letter> ::= '0' | 'b' | 'c' | 'd' " + nl
	see "<movement> ::= 'DRIVE' | 'BACK' | 'LEFT' | 'RIGHT' | 'SPINL' | 'SPINR' " + nl + nl

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# tokenizes input based on spaces and semicolon
func tokenize(input)
    input = trim(input)
    tokens = []
    word = ""
    for c in input
        if c = " " or c = ";"
            if word != ""
                add(tokens, word)
                word = ""
            ok
            if c = ";"
                add(tokens, ";")
            ok
        else
            word += c
        ok
    next
    if word != ""
        add(tokens, word)
    ok
    return tokens

#++++++++++++++++++++++++++++++++++++++++Trying out the derivation+++++++++++++++++++++++++++++++++
# Function to perform rightmost derivation with error detection
func RightmostDerivation(input)
    derivations = []
    error = ""

    # Split input into tokens
    tokens = tokenize(input)
	
    # Check start and end conditions
    if len(tokens) < 2 or tokens[1] != "wake"
        error = "Error: sentence must start with 'wake'"
    elseif tokens[len(tokens)] != "sleep"
        error = "Error: Sentence must end with 'sleep'"
    else
        # Count the number of buttons
        keyCount = 0
        for token in tokens
            if token = "key"
                keyCount = keyCount + 1
            ok
        next
	see "this is the keys " + keyCount + nl
        # Only proceed if there's no error and at least one button
	# Derivations for keys
        if error = "" and keyCount > 0
            # Initial derivation step
            add(derivations, "program -> wake <keys> sleep")

            # Generate derivations based on button count
            derivation = "-> wake <keys> sleep"
            for i = 2 to keyCount
                lastKeysPos = substr(derivation, "<keys>")
                if lastKeysPos > 0
                    derivation = substr(derivation, 1, lastKeysPos - 1) + 
                                 "<key> <keys> sleep" + 
                                 substr(derivation, lastKeysPos + 16)
                    add(derivations, derivation)
                ok
            next

            # Final step: replace last <statement_list> with <statement>
            lastKeysPos = substr(derivation, "<keys>")
            if lastKeysPos > 0
                derivation = substr(derivation, 1, lastKeysPos - 1) + 
                             "<key> sleep" + 
                             substr(derivation, lastKeysPos + 16)
                add(derivations, derivation)
            ok
        ok

	# Derivation to check if the buttons have ";" and if the have a movement property



    ok

    return [derivations, error]

    

/*# Function to print derivations
func PrintDerivations(derivations)
    for derivation in derivations
        see derivation + nl
    next 
*/

# Main program
func main ()
    # using double spaces (+ nl + nl) for formatting only
    see "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + nl + nl
    see "THIS IS THE GRAMMAR" + nl + nl
    see PrintGrammar()
	
    see "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + nl + nl
    see "Please enter a sentence: " give sentence

    # For debugging purposes checking if the tokenize works
    see "Tokens: "
    see tokenize(sentence) + nl

    # Testing out the partial derivation thingy
    see "Derivation: " + nl
    result = RightmostDerivation(sentence)
    derivations = result[1]
    error = result[2]

see "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + nl
    # Debugging this stuff
    see result[1] + nl
    # PrintDerivations(derivations)
    if error != ""
        see nl + error + nl
    ok
return 0
   

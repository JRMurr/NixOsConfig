function c --argument-names 'filename' --description "open editor alias"
    if test -n "$filename"
        $EDITOR $filename
    else
        $EDITOR $PWD
    end
end
'-------------------------------------------------------------------------------
' SearchRules_MinLength
'-------------------------------------------------------------------------------
function SearchRules_MinLength() as integer
    return 3
end function

'-------------------------------------------------------------------------------
' SearchRules_MaxLength
'-------------------------------------------------------------------------------
function SearchRules_MaxLength() as integer
    return 25
end function

'-------------------------------------------------------------------------------
' SearchRules_NormalizeTerm
'-------------------------------------------------------------------------------
function SearchRules_NormalizeTerm(value as dynamic) as string
    return StringUtils_CollapseWhitespace(SafeString(value, ""))
end function

'-------------------------------------------------------------------------------
' SearchRules_BuildContextTitle
'-------------------------------------------------------------------------------
function SearchRules_BuildContextTitle(searchTerm as dynamic) as string
    return "Search results... " + SearchRules_NormalizeTerm(searchTerm)
end function

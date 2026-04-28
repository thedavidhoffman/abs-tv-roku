'-------------------------------------------------------------------------------
' Color Values
'-------------------------------------------------------------------------------
' Use numeric hex values, such as &h12112BFF, when assigning colors directly to
' SceneGraph node fields from BrightScript, such as Rectangle.color or
' Label.color. Use string hex values, such as "0x292836FF", only for APIs that
' explicitly expect color strings. Roku standard dialog palette fields are one
' example of that string-based format.
'
'-------------------------------------------------------------------------------
' Color
'-------------------------------------------------------------------------------
function Color(themeName = "Default" as string) as object
    if themeName = "Default" then return ThemeDefault()

    return ThemeDefault()
end function

'-------------------------------------------------------------------------------
' ThemeDefault
'-------------------------------------------------------------------------------
function ThemeDefault() as object

    BACKGROUND_PRIMARY = &h292836FF
    BACKGROUND_SECONDARY = &h313040FF

    return {
        background: {
            header: &h12112BFF
            primary: BACKGROUND_PRIMARY
            secondary: BACKGROUND_SECONDARY
        }
        dialog: {
            backdrop: BACKGROUND_SECONDARY
            background: BACKGROUND_PRIMARY
        }
    }
end function

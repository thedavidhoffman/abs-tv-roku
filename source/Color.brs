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
function Color() as object

    PRIMARY_BUTTON_HIGHLIGHT = &h0F1A2AFF
    PRIMARY_BUTTON_HIGHLIGHT_HEX = "0xh0F1A2AFF"

    return {
        background: {
            header: &h12112BFF
            primary: &h292836FF
            secondary: &h313040FF
        }
        dialog: {
            backgroundHex: "0x313040FF"
            titleHex: "0xF3F7FBFF"
            textHex: "0xF3F7FBFF"
            focusHex: "0xF3F7FBFF"
            focusTextHex: "0x292836FF"
            secondaryHex: "0xF3F7FB66"
            footprintHex: "0xF3F7FB66"
        }
    }
end function

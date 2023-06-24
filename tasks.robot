*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PRF file.
...                 Saves screenshot of the ordered robot.
...                 Embeds the sscreenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem

*** Variables ***
${REICEPTS_PDF_TEMP_PATH}=    ${OUTPUT DIR}${/}receipts
${ROBOTS_IMAGE_TEMP_PATH}=    ${OUTPUT DIR}${/}robots

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get Orders
    FOR  ${order}  IN  @{orders}
        Process Order    ${order}
    END
    Create ZIP package from PDF files
    [Teardown]    Clean up
    
*** Keywords ***
Set up directories
    Create Directory    ${OUTPUT DIR}
    Create Directory    ${REICEPTS_PDF_TEMP_PATH}
    Create Directory    ${ROBOTS_IMAGE_TEMP_PATH}
    
Open the robot order website
    Open Available Browser    url=https://robotsparebinindustries.com/#/robot-order

    
Get Orders
    Download    url=https://robotsparebinindustries.com/orders.csv    target_file=${OUTPUT DIR}${/}orders.csv    overwrite=True
    ${orders_table}=    Read table from CSV    path=${OUTPUT DIR}${/}orders.csv    header=True
    RETURN    ${orders_table}
    
Process Order
    [Arguments]    ${order}
    Close the annoying modal
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[type=number]    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    id:preview
    Wait Until Keyword Succeeds    5x    1 sec    Submit Order
    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Click Button    id:order-another

Close the annoying modal
    Wait Until Element Is Visible    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]
    Click Button    xpath:/html/body/div/div/div[2]/div/div/div/div/div/button[1]

Submit Order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt    2 sec

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    ${receiptHTML}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf}=    Set Variable    ${REICEPTS_PDF_TEMP_PATH}${/}reicept-RobotSpareBin-${orderNumber}.pdf
    Html To Pdf    ${receiptHTML}    ${pdf}
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    ${screenshot}=    Set Variable    ${ROBOTS_IMAGE_TEMP_PATH}${/}robot-RobotSpareBin-${orderNumber}.png
    Screenshot    id:robot-preview-image    ${screenshot}
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
        [Arguments]    ${screenshot}    ${pdf}
        ${files}=    Create List    ${screenshot}
        Open Pdf    ${pdf}
        Add Files To Pdf    ${files}    ${pdf}    True
        Close Pdf    ${pdf}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT DIR}${/}Receipts.zip
    Archive Folder With Zip    ${OUTPUT DIR}${/}receipts    ${zip_file_name}

Clean up
    Close Browser
    Remove Directory    ${REICEPTS_PDF_TEMP_PATH}    True
    Remove Directory    ${ROBOTS_IMAGE_TEMP_PATH}    True
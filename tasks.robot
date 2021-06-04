# +
*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Robocloud.Secrets
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs



# +
*** Keywords ***
Open the robot order website
    ${website_url}=     Get secret      credentials
    Open Available Browser          ${website_url}[robosparewebsite]
    Click Link      Order your robot!
    

Collect orders.csv url from user
    Add text input      ordersurl      label=Enter the orders.csv URL
    ${response} =   Run Dialog
    [Return]        ${response.ordersurl}
    
    
Get orders
    [Arguments]     ${url_provided_by_user}
    Download        ${url_provided_by_user}      overwrite=true
    ${table}=    Read table from CSV    orders.csv
    [Return]         ${table}


Close the annoying modal
    Click Element When Visible      css:.btn.btn-dark


Fill the Form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body     ${row}[Body]
    Input Text      css:.form-control        ${row}[Legs]
    Input Text      id:address      ${row}[Address]


Preview the robot
   Click Button        id:preview
   Wait Until Keyword Succeeds    5x   1sec    Is Element Visible      id:robot-preview-image

Submit the order
    Click Button When Visible    id:order
    ${receipt element present}=     Is Element Visible      id:receipt
        IF      ${receipt element present}
            Scroll Element Into View     id:receipt
        ELSE
            FOR    ${i}    IN RANGE    9999999
                ${receipt element present}=     Is Element Visible    id:receipt
                Exit For Loop If    ${receipt element present}
                Click Button        id:order
            END
        END
    


Store the receipt as a PDF file
    [Arguments]     ${Order Number}
    ${order_receipt}=   Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt}    ${CURDIR}${/}output${/}${Order Number}.pdf
    [Return]         ${CURDIR}${/}output${/}${Order Number}.pdf


Take a screenshot of the Robot
    [Arguments]    ${Order Number}
    Capture Element Screenshot      id:robot-preview-image   ${CURDIR}${/}screenshot${/}${Order Number}.png       
    [Return]        ${CURDIR}${/}screenshot${/}${Order Number}.png


Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}
    Close pdf   ${pdf}

Go to order another robot
    Click Button        id:order-another
    
  
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output    receipts.zip
# -

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${url_provided_by_user}=    Collect orders.csv url from user 
        ${orders}=    Get orders        ${url_provided_by_user}
        FOR    ${row}    IN    @{orders}
            Close the annoying modal
            Fill the form    ${row}
            Preview the robot
            Submit the order
            ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
            Go to order another robot
        END
    Create a ZIP file of the receipts
    Close Browser

*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get Orders
    Make Orders    ${orders}
    Archive Orders with ZIP

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=         10x
${GLOBAL_RETRY_INTERVAL}=       0.5s

*** Keywords ***
Open the robot order website
    Open Browser    https://robotsparebinindustries.com/#/robot-order

Get Orders
    Download    url=https://robotsparebinindustries.com/orders.csv    overwrite=${True}
    ${orders}=    Read table from CSV     path=orders.csv    header=${True}
    RETURN    ${orders}

Make Orders
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Wait Until Keyword Succeeds
        ...    ${GLOBAL_RETRY_AMOUNT}
        ...    ${GLOBAL_RETRY_INTERVAL}
        ...    Fill Form    ${order}
    END


Fill Form
    [Arguments]    ${order}
    Click Button    Yep
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    group_name=body    value=${order}[Body]
    Input Text    //form/div[3]/input   text=${order}[Legs]
    Input Text    address    text=${order}[Address]
    Click Button    Preview
    Wait Until Element Is Visible    locator=//*[@id="robot-preview-image"]/img[1]
    Wait Until Element Is Visible    locator=//*[@id="robot-preview-image"]/img[2]
    Wait Until Element Is Visible    locator=//*[@id="robot-preview-image"]/img[3]
    Screenshot    //*[@id="robot-preview-image"]    filename=${OUTPUT_DIR}${/}image${/}image${order}[Order number].png
    Wait Until Keyword Succeeds
    ...    ${GLOBAL_RETRY_AMOUNT}
    ...    ${GLOBAL_RETRY_INTERVAL}
    ...    Submit Form    ${order}
    Merge ScreenShot Preview and Receipt    ${order}
    Click Button    locator=//*[@id="order-another"]

Submit Form
    [Arguments]    ${order}
    Click Button    //*[@id="order"]
    Wait Until Element Is Visible    locator=//*[@id="order-completion"]

Merge ScreenShot Preview and Receipt
    [Arguments]    ${order}
    ${elem}=    Get Element Attribute    //*[@id="order-completion"]    attribute=outerHTML
    Html To Pdf    content=${elem}    output_path=${OUTPUT_DIR}${/}pdf${/}receipts${order}[Order number].pdf
    ${file}=    Create List    ${OUTPUT_DIR}${/}image${/}image${order}[Order number].png
    Add Files To Pdf    files=${file}    target_document=${OUTPUT_DIR}${/}pdf${/}receipts${order}[Order number].pdf    append=${True}

Archive Orders with ZIP
    Archive Folder With Zip    folder=${OUTPUT_DIR}${/}pdf    archive_name=orders.zip
*** Settings ***
Library    Collections
Library    OperatingSystem
Library    log-table.py
# Resource    log-table.resource


*** Test Cases ***
Test_Generate_Table_With_1_Level_Flat_Data
    [Documentation]
    ...    = SLOGAN: =
    ...    Test the Log Table keyword with 1 level flat (non-nested) dictionary data.
    ...    = PREREQ: =
    ...    = STEPS: =
    ...    - Create test data with simple flat dictionaries.
    ...    - Generate HTML table.
    ...    - Save output to file for visual inspection.
    ...    == Pass ==
    ...    - HTML table is generated successfully with 6 columns and 5 data rows.
    ...    == Fail ==
    ...    - Keyword fails or produces invalid HTML.
    ...
    ...    === Test Case Version 1.0 ===

    [Tags]    TEST

    # Create flat test data
    &{row1}    Create Dictionary    field_1=1    field_2=2    field_3=3    field_4=A    field_5=AA    field_6=AAA
    &{row2}    Create Dictionary    field_1=4    field_2=5    field_3=6    field_4=B    field_5=BB    field_6=BBB
    &{row3}    Create Dictionary    field_1=7    field_5=CC    field_6=CCC
    &{row4}    Create Dictionary    field_1=10    field_2=11    field_3=12    field_4=D    field_5=DD    field_6=DDD
    &{row5}    Create Dictionary    field_1=13    field_2=14    field_3=15    field_4=E    field_5=EE    field_6=EEE

    @{table_list}    Create List    ${row1}    ${row2}    ${row3}    ${row4}    ${row5}

    # Generate HTML table
    Log Table    ${table_list}


Test_Generate_Table_With_2_Level_Nested_Data
    [Documentation]
    ...    = SLOGAN: =
    ...    Test the Log Table keyword with 2 levels of nested dictionary data.
    ...    = PREREQ: =
    ...    = STEPS: =
    ...    - Create test data with 2 levels of nested dictionaries.
    ...    - Generate HTML table.
    ...    - Save output to file for visual inspection.
    ...    == Pass ==
    ...    - HTML table is generated successfully.
    ...    == Fail ==
    ...    - Keyword fails or produces invalid HTML.
    ...
    ...    === Test Case Version 1.0 ===

    [Tags]    TEST

    # Create test data matching the example
    &{row1_nested1}    Create Dictionary    field_3_1=value_1_3_1_1    field_3_2=value_1_3_1_2
    &{row1_nested2}    Create Dictionary    field_3_1=value_1_3_2_1    field_3_2=value_1_3_2_2    field_3_3=value_1_3_2_3
    @{row1_field3}    Create List    ${row1_nested1}    ${row1_nested2}
    &{row1}    Create Dictionary    field_1=value_1_1    field_2=value_1_2    field_3=${row1_field3}

    &{row2_nested1}    Create Dictionary    field_3_1=value_2_3_1_1    field_3_2=value_1_3_1_2
    @{row2_field3}    Create List    ${row2_nested1}
    &{row2}    Create Dictionary    field_1=value_2_1    field_2=value_2_2    field_3=${row2_field3}

    @{table_list}    Create List    ${row1}    ${row2}

    # Generate HTML table
    Log Table    ${table_list}


Test_Generate_Table_With_3_Level_Nested_Data
    [Documentation]
    ...    = SLOGAN: =
    ...    Test the Log Table keyword with 3 levels of nested dictionary data.
    ...    = PREREQ: =
    ...    = STEPS: =
    ...    - Create test data with 3 levels of nested dictionaries.
    ...    - Generate HTML table.
    ...    - Save output to file for visual inspection.
    ...    == Pass ==
    ...    - HTML table is generated successfully with proper 3-level nesting.
    ...    == Fail ==
    ...    - Keyword fails or produces invalid HTML.
    ...
    ...    === Test Case Version 1.0 ===

    [Tags]    TEST

    # Row 1: field_4 has 2 nested items, each with sub-4-field_1 having 2 nested items
    &{row1_f4_sf1_n1}    Create Dictionary    sub_1=1_4_1_A    sub_2=1_4_1_B
    &{row1_f4_sf1_n2}    Create Dictionary    sub_1=1_4_1_C    sub_2=1_4_1_D
    @{row1_f4_sf1_list}    Create List    ${row1_f4_sf1_n1}    ${row1_f4_sf1_n2}

    &{row1_f4_n1}    Create Dictionary    sub-4-field_1=${row1_f4_sf1_list}    sub-4-field_2=1_4_1

    &{row1_f4_sf1_n3}    Create Dictionary    sub_1=1_4_2_A    sub_2=1_4_2_B
    &{row1_f4_sf1_n4}    Create Dictionary    sub_1=1_4_2_D    sub_2=1_4_2_E
    @{row1_f4_sf1_list2}    Create List    ${row1_f4_sf1_n3}    ${row1_f4_sf1_n4}

    &{row1_f4_n2}    Create Dictionary    sub-4-field_1=${row1_f4_sf1_list2}    sub-4-field_2=1_4_2

    @{row1_field4}    Create List    ${row1_f4_n1}    ${row1_f4_n2}
    &{row1}    Create Dictionary    field_1=1_1    field_2=1_2    field_3=1_3    field_4=${row1_field4}    field_5=1_5    field_6=1_6

    # Row 2: Similar structure
    &{row2_f4_sf1_n1}    Create Dictionary    sub_1=2_4_1_A    sub_2=2_4_1_B
    &{row2_f4_sf1_n2}    Create Dictionary    sub_1=2_4_1_C    sub_2=2_4_1_D
    @{row2_f4_sf1_list}    Create List    ${row2_f4_sf1_n1}    ${row2_f4_sf1_n2}

    &{row2_f4_n1}    Create Dictionary    sub-4-field_1=${row2_f4_sf1_list}    sub-4-field_2=2_4_1

    &{row2_f4_sf1_n3}    Create Dictionary    sub_1=2_4_2_A    sub_2=2_4_2_B
    &{row2_f4_sf1_n4}    Create Dictionary    sub_1=2_4_2_D    sub_2=2_4_2_E
    @{row2_f4_sf1_list2}    Create List    ${row2_f4_sf1_n3}    ${row2_f4_sf1_n4}

    &{row2_f4_n2}    Create Dictionary    sub-4-field_1=${row2_f4_sf1_list2}    sub-4-field_2=2_4_2

    @{row2_field4}    Create List    ${row2_f4_n1}    ${row2_f4_n2}
    &{row2}    Create Dictionary    field_1=2_1    field_2=2_2    field_3=2_3    field_4=${row2_field4}    field_5=2_5    field_6=2_6

    @{table_list}    Create List    ${row1}    ${row2}

    # Generate HTML table
    Log Table    ${table_list}


Test_Generate_Table_With_4_Level_Nested_Data
    [Documentation]
    ...    = SLOGAN: =
    ...    Test the Log Table keyword with 4 levels of nested dictionary data.
    ...    = PREREQ: =
    ...    = STEPS: =
    ...    - Create test data with 4 levels of nested dictionaries.
    ...    - Generate HTML table.
    ...    - Save output to file for visual inspection.
    ...    == Pass ==
    ...    - HTML table is generated successfully with proper 4-level nesting.
    ...    == Fail ==
    ...    - Keyword fails or produces invalid HTML.
    ...
    ...    === Test Case Version 1.0 ===

    [Tags]    TEST

    # Row 1: 4-level nesting - field_4 > sub-4-field_1 > sub_1 > sub_1-1/sub_1-2
    # Level 4: sub_1 has 2 nested items with sub_1-1 and sub_1-2
    &{r1_s1_n1}    Create Dictionary    sub_1-1=1_4_1_1-1_A    sub_1-2=1_4_1_1-1_B
    &{r1_s1_n2}    Create Dictionary    sub_1-1=1_4_1_1-2_C    sub_1-2=1_4_1_1_2_D
    @{r1_s1_list}    Create List    ${r1_s1_n1}    ${r1_s1_n2}

    # Level 3: sub-4-field_1 has 2 items, first with nested sub_1, second with nested sub_1
    &{r1_sf1_n1}    Create Dictionary    sub_1=${r1_s1_list}    sub_2=1_4_1_1

    &{r1_s1_n3}    Create Dictionary    sub_1-1=1_4_1_2-1_A    sub_1-2=1_4_1_2-1_B
    &{r1_s1_n4}    Create Dictionary    sub_1-1=1_4_1_2_2_D    sub_1-2=1_4_1_2_2_E
    @{r1_s1_list2}    Create List    ${r1_s1_n3}    ${r1_s1_n4}

    &{r1_sf1_n2}    Create Dictionary    sub_1=${r1_s1_list2}    sub_2=1_4_1_2

    @{r1_sf1_list}    Create List    ${r1_sf1_n1}    ${r1_sf1_n2}

    # Level 2: field_4 has 1 item with nested sub-4-field_1
    &{r1_f4_n1}    Create Dictionary    sub-4-field_1=${r1_sf1_list}    sub-4-field_2=1_4_1

    @{r1_field4}    Create List    ${r1_f4_n1}

    # Level 1: Main row
    &{row1}    Create Dictionary    field_1=1_1    field_2=1_2    field_3=1_3    field_4=${r1_field4}    field_5=1_5    field_6=1_6

    # Row 2: Similar 4-level structure
    &{r2_s1_n1}    Create Dictionary    sub_1-1=2_4_1_1-1_A    sub_1-2=2_4_1_1-1_B
    &{r2_s1_n2}    Create Dictionary    sub_1-1=2_4_1_1-2_C    sub_1-2=2_4_1_1_2_D
    @{r2_s1_list}    Create List    ${r2_s1_n1}    ${r2_s1_n2}

    &{r2_sf1_n1}    Create Dictionary    sub_1=${r2_s1_list}    sub_2=2_4_1_1

    &{r2_s1_n3}    Create Dictionary    sub_1-1=2_4_1_2-1_A    sub_1-2=2_4_1_2-1_B
    &{r2_s1_n4}    Create Dictionary    sub_1-1=2_4_1_2_2_D    sub_1-2=2_4_1_2_2_E
    @{r2_s1_list2}    Create List    ${r2_s1_n3}    ${r2_s1_n4}

    &{r2_sf1_n2}    Create Dictionary    sub_1=${r2_s1_list2}    sub_2=2_4_1_2

    @{r2_sf1_list}    Create List    ${r2_sf1_n1}    ${r2_sf1_n2}

    &{r2_f4_n1}    Create Dictionary    sub-4-field_1=${r2_sf1_list}    sub-4-field_2=2_4_1

    @{r2_field4}    Create List    ${r2_f4_n1}

    &{row2}    Create Dictionary    field_1=2_1    field_2=2_2    field_3=2_3    field_4=${r2_field4}    field_5=2_5    field_6=2_6

    @{table_list}    Create List    ${row1}    ${row2}

    # Generate HTML table
    Log Table    ${table_list}

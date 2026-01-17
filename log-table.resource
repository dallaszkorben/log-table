*** Keywords ***
Log Table
    [Documentation]
    ...    Generates and logs tables (HTML and optionally text-based) from a list of dictionaries with nested structure support.
    ...    == Arguments ==
    ...    - ``table_list``: list - List of dictionaries where values can be strings or lists of dictionaries.
    ...    - ``console``: bool - [Optional] If ${True}, generates and logs text-based table to console. If ${False}, only HTML table is generated.
    ...      Default: ${True}
    ...    == Output ==
    ...    - Logs HTML table to report (always)
    ...    - Logs text-based table to console (only if console=${True})
    ...    == Examples ==
    ...    # Example 1: Simple flat data (1 level)
    ...    | ${row1}    Create Dictionary    name=Alice    age=30    city=NYC
    ...    | ${row2}    Create Dictionary    name=Bob      age=25    city=LA
    ...    | @{table}    Create List    ${row1}    ${row2}
    ...    | Log Table    ${table}
    ...    # Text output:
    ...    # +-------+-----+------+
    ...    # | name  | age | city |
    ...    # +=======+=====+======+
    ...    # | Alice | 30  | NYC  |
    ...    # +-------+-----+------+
    ...    # | Bob   | 25  | LA   |
    ...    # +-------+-----+------+
    ...    
    ...    # Example 2: Nested data (2 levels) - Address history
    ...    | ${addr1}    Create Dictionary    street=Main St    zip=10001
    ...    | ${addr2}    Create Dictionary    street=5th Ave    zip=10002
    ...    | ${addr3}    Create Dictionary    street=Oak Ave    zip=90001
    ...    | ${addr4}    Create Dictionary    street=Elm St     zip=90002
    ...    | ${addr5}    Create Dictionary    street=Pine Rd    zip=90003
    ...    | @{addresses1}    Create List    ${addr1}    ${addr2}
    ...    | @{addresses2}    Create List    ${addr3}    ${addr4}    ${addr5}
    ...    | ${row1}    Create Dictionary    name=Alice    address=${addresses1}
    ...    | ${row2}    Create Dictionary    name=Bob      address=${addresses2}
    ...    | @{table}    Create List    ${row1}    ${row2}
    ...    | Log Table    ${table}
    ...    # Text output (Alice has 2 addresses, Bob has 3):
    ...    # +-------+---------+-------+
    ...    # | name  |     address     |
    ...    # |       +---------+-------+
    ...    # |       | street  |  zip  |
    ...    # +=======+=========+=======+
    ...    # | Alice | Main St | 10001 |
    ...    # |       +---------+-------+
    ...    # |       | 5th Ave | 10002 |
    ...    # +-------+---------+-------+
    ...    # | Bob   | Oak Ave | 90001 |
    ...    # |       +---------+-------+
    ...    # |       | Elm St  | 90002 |
    ...    # |       +---------+-------+
    ...    # |       | Pine Rd | 90003 |
    ...    # +-------+---------+-------+
    ...    
    ...    # Example 3: Skip console output
    ...    | Log Table    ${table}    console=${False}
    ...    == Notes ==
    ...    - Header background: grey (#d3d3d3)
    ...    - Cell background: yellow (#ffffe0)
    ...    - Supports recursive nested dictionaries
    ...    - Validates structure consistency across all rows
    ...    - When console=${False}, text table generation is skipped for better performance

    [Arguments]    ${table_list}    ${console}=${True}

    # STEP 1: Analyze the table structure
    # WHY: We need to understand the nested structure to generate proper headers with rowspan/colspan
    # WHAT: Extracts field hierarchy, merges structures from all rows, calculates max nesting depth
    ${header_structure}    ${max_depth}    _Html Based Analyze Table Structure    ${table_list}

    # STEP 2: Generate HTML table
    # WHY: HTML format is needed for rich display in reports with proper styling
    # WHAT: Creates HTML with proper <table>, <tr>, <th>, <td> tags and rowspan/colspan attributes
    ${html}    _Html Based Log Table    ${table_list}    ${header_structure}    ${max_depth}
    Log    ${html}    console=${False}
    Log    ${html}    html=${True}    console=${False}

    # STEP 3: Generate text-based (ASCII) table (optional)
    # WHY: Text format is needed for console output and plain text logs
    # WHAT: Creates ASCII table with borders, proper alignment, and visual cell merging
    IF    ${console}
        ${text}    _Text Based Log Table    ${header_structure}    ${max_depth}    ${table_list}
        Log    \n${text}    console=${True}
    END


_Html Based Analyze Table Structure
    # PURPOSE: Analyze all data rows to build a unified header structure
    # WHY: Different rows may have different fields or nesting levels, we need to merge them all
    # RETURNS: header_structure (list of field info dicts), max_depth (int)
    [Arguments]    ${table_list}

    ${header_structure}    Create List
    ${max_depth}    Set Variable    ${1}

    # Process each data row to extract its structure
    FOR    ${row}    IN    @{table_list}
        # Extract structure from this row (recursive for nested fields)
        ${current_structure}    _Html Based Extract Structure    ${row}    ${1}
        
        # Merge with existing structure (handles fields that appear in some rows but not others)
        ${header_structure}    _Html Based Merge Structures    ${header_structure}    ${current_structure}
        
        # Track maximum nesting depth (determines number of header rows needed)
        ${row_depth}    _Html Based Calculate Depth    ${current_structure}
        IF    ${row_depth} > ${max_depth}
            ${max_depth}    Set Variable    ${row_depth}
        END
    END

    RETURN    ${header_structure}    ${max_depth}


_Html Based Log Table
    [Arguments]    ${table_list}    ${header_structure}    ${max_depth}

    # Generate CSS styles once at the beginning
    ${style}    Set Variable    <style>.th{background-color:#d3d3d3;text-align:center}.td{background-color:#ffffe0;text-align:center}</style>
    ${html}    Set Variable    ${style}<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">
    ${html}    Catenate    SEPARATOR=    ${html}    ${SPACE}${\n}

    ${header_html}    _Html Based Generate Header Rows    ${header_structure}    ${max_depth}
    ${html}    Catenate    SEPARATOR=    ${html}    ${header_html}

    FOR    ${row_data}    IN    @{table_list}
        ${row_html}    _Html Based Generate Data Row    ${row_data}    ${header_structure}
        ${html}    Catenate    SEPARATOR=    ${html}    ${row_html}
    END

    ${html}    Catenate    SEPARATOR=    ${html}    </table>

    RETURN    ${html}


_Html Based Extract Structure
    # PURPOSE: Recursively extract field structure from a dictionary
    # WHY: We need to know which fields are nested (lists) vs simple (strings) to build headers
    # HOW: For each key-value pair, check if value is a list (nested) or not (simple)
    # RETURNS: List of field info dicts with {name, nested, depth}
    [Arguments]    ${data}    ${depth}

    ${structure}    Create List

    FOR    ${key}    IN    @{data.keys()}
        ${value}    Get From Dictionary    ${data}    ${key}
        ${type}    Evaluate    type($value).__name__

        IF    '${type}' == 'list'
            # This field contains nested data (list of dictionaries)
            # WHY: Need to recursively analyze nested structure
            ${nested_structure}    Create List
            FOR    ${item}    IN    @{value}
                ${item_structure}    _Html Based Extract Structure    ${item}    ${depth + 1}
                # Merge structures from all nested items (they may have different fields)
                ${nested_structure}    _Html Based Merge Structures    ${nested_structure}    ${item_structure}
            END
            ${field_info}    Create Dictionary    name=${key}    nested=${nested_structure}    depth=${depth}
        ELSE
            # This field contains simple data (string, number, etc.)
            ${field_info}    Create Dictionary    name=${key}    nested=${None}    depth=${depth}
        END

        Append To List    ${structure}    ${field_info}
    END

    RETURN    ${structure}


_Html Based Merge Structures
    # PURPOSE: Merge two structure lists to create a unified structure
    # WHY: Different rows may have different fields - we need all possible fields in headers
    # HOW: For each field in new_structure, find matching field in base_structure and merge
    # EXAMPLE: Row1 has {a, b}, Row2 has {b, c} → merged has {a, b, c}
    # RETURNS: Merged structure list
    [Arguments]    ${base_structure}    ${new_structure}

    # Base case: if base is empty, return new structure
    IF    not ${base_structure}
        RETURN    ${new_structure}
    END

    ${merged}    Create List

    # Process each field from new_structure
    FOR    ${new_field}    IN    @{new_structure}
        ${found}    Set Variable    ${False}
        ${merged_field}    Set Variable    ${None}

        # Check if this field exists in base_structure
        FOR    ${base_field}    IN    @{base_structure}
            IF    '${base_field}[name]' == '${new_field}[name]'
                ${found}    Set Variable    ${True}
                # Field exists in both - need to merge nested structures if both are nested
                IF    ${new_field}[nested] is not None and ${base_field}[nested] is not None
                    # Both have nested structures - recursively merge them
                    ${merged_nested}    _Html Based Merge Structures    ${base_field}[nested]    ${new_field}[nested]
                    ${merged_field}    Create Dictionary    name=${base_field}[name]    nested=${merged_nested}    depth=${base_field}[depth]
                ELSE IF    ${new_field}[nested] is not None
                    # Only new has nested structure - use it
                    ${merged_field}    Set Variable    ${new_field}
                ELSE
                    # Neither or only base has nested - use base
                    ${merged_field}    Set Variable    ${base_field}
                END
                BREAK
            END
        END

        # Add field to merged list (avoid duplicates)
        IF    not ${found}
            Append To List    ${merged}    ${new_field}
        ELSE IF    ${merged_field} is not None
            ${already_added}    Set Variable    ${False}
            FOR    ${item}    IN    @{merged}
                IF    '${item}[name]' == '${merged_field}[name]'
                    ${already_added}    Set Variable    ${True}
                    BREAK
                END
            END
            IF    not ${already_added}
                Append To List    ${merged}    ${merged_field}
            END
        END
    END

    # Add any fields from base_structure that weren't in new_structure
    FOR    ${base_field}    IN    @{base_structure}
        ${exists}    Set Variable    ${False}
        FOR    ${item}    IN    @{merged}
            IF    '${item}[name]' == '${base_field}[name]'
                ${exists}    Set Variable    ${True}
                BREAK
            END
        END
        IF    not ${exists}
            Append To List    ${merged}    ${base_field}
        END
    END

    RETURN    ${merged}


_Html Based Calculate Depth
    # PURPOSE: Calculate maximum nesting depth in the structure
    # WHY: Determines how many header rows we need (one row per nesting level)
    # HOW: Recursively traverse nested structures and track maximum depth
    # EXAMPLE: {field1: simple, field2: {nested1: simple}} has depth=2
    # RETURNS: Maximum depth (int)
    [Arguments]    ${structure}

    ${max_depth}    Set Variable    ${1}

    FOR    ${field}    IN    @{structure}
        IF    ${field}[nested] is not None
            # This field has nested structure - calculate its depth recursively
            ${nested_depth}    _Html Based Calculate Depth    ${field}[nested]
            ${total_depth}    Evaluate    ${field}[depth] + ${nested_depth}
            IF    ${total_depth} > ${max_depth}
                ${max_depth}    Set Variable    ${total_depth}
            END
        END
    END

    RETURN    ${max_depth}


_Html Based Generate Header Rows
    [Arguments]    ${header_structure}    ${max_depth}

    ${html}    Set Variable    ${EMPTY}

    FOR    ${level}    IN RANGE    ${max_depth}
        ${html}    Catenate    SEPARATOR=    ${html}    <tr>
        ${row_html}    _Html Based Generate Header Row Level    ${header_structure}    ${level}    ${1}    ${max_depth}
        ${html}    Catenate    SEPARATOR=    ${html}    ${row_html}
        ${html}    Catenate    SEPARATOR=    ${html}    </tr>${SPACE}${\n}
    END

    RETURN    ${html}


_Html Based Generate Header Row Level
    [Arguments]    ${structure}    ${target_level}    ${current_level}    ${max_depth}

    ${html}    Set Variable    ${EMPTY}

    FOR    ${field}    IN    @{structure}
        IF    ${current_level} == ${target_level} + 1
            ${colspan}    _Html Based Count Leaf Columns    ${field}
            IF    ${field}[nested] is not None
                ${rowspan}    Set Variable    ${1}
            ELSE
                ${rowspan}    Evaluate    ${max_depth} - ${current_level} + 1
            END
            ${html}    Catenate    SEPARATOR=    ${html}    <th rowspan="${rowspan}" colspan="${colspan}" class="th">${field}[name]</th>
        ELSE IF    ${field}[nested] is not None and ${current_level} < ${target_level} + 1
            ${nested_html}    _Html Based Generate Header Row Level    ${field}[nested]    ${target_level}    ${current_level + 1}    ${max_depth}
            ${html}    Catenate    SEPARATOR=    ${html}    ${nested_html}
        END
    END

    RETURN    ${html}


_Html Based Count Leaf Columns
    # PURPOSE: Count how many leaf (bottom-level) columns a field spans
    # WHY: Determines colspan value for HTML table headers
    # HOW: If field is simple, it's 1 column. If nested, sum all nested leaf columns recursively
    # EXAMPLE: {field1: {sub1: simple, sub2: simple}} has 2 leaf columns
    # RETURNS: Number of leaf columns (int)
    [Arguments]    ${field}

    # Base case: simple field = 1 column
    IF    ${field}[nested] is None
        RETURN    ${1}
    END

    # Recursive case: sum leaf columns from all nested fields
    ${count}    Set Variable    ${0}
    FOR    ${nested_field}    IN    @{field}[nested]
        ${nested_count}    _Html Based Count Leaf Columns    ${nested_field}
        ${count}    Evaluate    ${count} + ${nested_count}
    END

    RETURN    ${count}


_Html Based Generate Data Row
    [Arguments]    ${row_data}    ${header_structure}

    ${cells}    _Html Based Extract Row Cells    ${row_data}    ${header_structure}
    ${max_rows}    _Html Based Calculate Max Nested Rows    ${cells}

    # Update rowspan for non-nested cells to span all rows
    FOR    ${cell}    IN    @{cells}
        ${is_nested}    Get From Dictionary    ${cell}    is_nested
        IF    not ${is_nested}
            Set To Dictionary    ${cell}    rowspan=${max_rows}
        END
    END

    ${html}    Set Variable    ${EMPTY}

    FOR    ${row_index}    IN RANGE    ${max_rows}
        ${html}    Catenate    SEPARATOR=    ${html}    <tr>
        ${row_html}    _Html Based Generate Data Row Cells    ${cells}    ${row_index}    ${max_rows}
        ${html}    Catenate    SEPARATOR=    ${html}    ${row_html}
        ${html}    Catenate    SEPARATOR=    ${html}    </tr>${SPACE}${\n}
    END

    RETURN    ${html}


_Html Based Generate Data Row Cells
    [Arguments]    ${cells}    ${row_index}    ${max_rows}

    ${html}    Set Variable    ${EMPTY}

    FOR    ${cell}    IN    @{cells}
        ${is_nested}    Get From Dictionary    ${cell}    is_nested
        IF    ${is_nested}
            ${nested_cells_list}    Get From Dictionary    ${cell}    nested_cells
            ${nested_cells_length}    Get Length    ${nested_cells_list}

            # Calculate which nested item this row belongs to
            ${accumulated_rows}    Set Variable    ${0}
            ${found}    Set Variable    ${False}
            ${current_nested_max_rows}    Set Variable    ${1}

            FOR    ${i}    IN RANGE    ${nested_cells_length}
                ${nested_cells}    Set Variable    ${nested_cells_list}[${i}]
                ${nested_max_rows}    _Html Based Calculate Max Nested Rows    ${nested_cells}
                ${new_accumulated}    Evaluate    ${accumulated_rows} + ${nested_max_rows}

                IF    ${row_index} < ${new_accumulated} and not ${found}
                    ${relative_row_index}    Evaluate    ${row_index} - ${accumulated_rows}
                    ${current_nested_max_rows}    Set Variable    ${nested_max_rows}
                    ${nested_html}    _Html Based Generate Data Row Cells    ${nested_cells}    ${relative_row_index}    ${nested_max_rows}
                    ${html}    Catenate    SEPARATOR=    ${html}    ${nested_html}
                    ${found}    Set Variable    ${True}
                END
                ${accumulated_rows}    Set Variable    ${new_accumulated}
            END

            # Fill empty cells if row_index is beyond all nested items
            IF    not ${found}
                ${leaf_count}    Get From Dictionary    ${cell}    leaf_count
                FOR    ${i}    IN RANGE    ${leaf_count}
                    ${html}    Catenate    SEPARATOR=    ${html}    <td class="td"></td>
                END
            END
        ELSE
            # Non-nested cells: calculate rowspan based on sibling nested cells
            IF    ${row_index} == 0
                # Find if there's a nested sibling to determine rowspan
                ${sibling_rowspan}    Set Variable    ${max_rows}

                # Check if any sibling cell is nested to get proper rowspan
                FOR    ${sibling_cell}    IN    @{cells}
                    ${sibling_is_nested}    Get From Dictionary    ${sibling_cell}    is_nested
                    IF    ${sibling_is_nested}
                        # Use the max_rows passed to this function as rowspan
                        ${sibling_rowspan}    Set Variable    ${max_rows}
                        BREAK
                    END
                END

                ${value}    Get From Dictionary    ${cell}    value
                ${html}    Catenate    SEPARATOR=    ${html}    <td rowspan="${sibling_rowspan}" class="td">${value}</td>
            END
        END
    END

    RETURN    ${html}


_Html Based Extract Row Cells
    # PURPOSE: Extract cell data from a data row, preserving nested structure
    # WHY: We need to know which cells are nested (multiple rows) vs simple (single row)
    # HOW: For each field in header structure, extract corresponding value from data row
    # CRITICAL: Nested cells store list of cell lists (NOT flattened) to preserve structure
    # RETURNS: List of cell info dicts with {value, rowspan, is_nested, nested_cells, leaf_count}
    [Arguments]    ${row_data}    ${header_structure}

    ${cells}    Create List

    FOR    ${field}    IN    @{header_structure}
        ${key}    Set Variable    ${field}[name]
        ${has_key}    Run Keyword And Return Status    Dictionary Should Contain Key    ${row_data}    ${key}

        IF    ${has_key}
            ${value}    Get From Dictionary    ${row_data}    ${key}
            ${type}    Evaluate    type($value).__name__

            IF    '${type}' == 'list'
                # Nested data: recursively extract cells from each nested item
                # WHY: Each nested item becomes a separate row in the table
                ${nested_cells_list}    Create List
                FOR    ${nested_item}    IN    @{value}
                    ${nested_cells}    _Html Based Extract Row Cells    ${nested_item}    ${field}[nested]
                    Append To List    ${nested_cells_list}    ${nested_cells}
                END
                ${nested_rows_length}    Get Length    ${nested_cells_list}
                ${leaf_count}    _Html Based Count Leaf Columns    ${field}
                ${cell_info}    Create Dictionary    value=${EMPTY}    rowspan=${nested_rows_length}    is_nested=${True}    nested_cells=${nested_cells_list}    leaf_count=${leaf_count}
            ELSE
                # Simple data: single value
                ${cell_info}    Create Dictionary    value=${value}    rowspan=${1}    is_nested=${False}    leaf_count=${1}
            END
        ELSE
            # Field missing in this row: create empty cell
            ${leaf_count}    _Html Based Count Leaf Columns    ${field}
            ${cell_info}    Create Dictionary    value=${EMPTY}    rowspan=${1}    is_nested=${False}    leaf_count=${leaf_count}
        END

        Append To List    ${cells}    ${cell_info}
    END

    RETURN    ${cells}


_Html Based Calculate Max Nested Rows
    # PURPOSE: Calculate how many table rows are needed for a list of cells
    # WHY: Nested cells require multiple rows (e.g., 2 nested items = 2 rows)
    # HOW: For nested cells, recursively sum rows from all nested items
    # EXAMPLE: Cell with 2 nested items, each having 2 sub-items = 2+2 = 4 rows total
    # RETURNS: Maximum number of rows needed (int)
    [Arguments]    ${cells}

    ${max_rows}    Set Variable    ${1}

    FOR    ${cell}    IN    @{cells}
        ${is_nested}    Get From Dictionary    ${cell}    is_nested
        IF    ${is_nested}
            # For nested cells, calculate total rows by summing all nested item rows
            # WHY: Each nested item occupies a contiguous block of rows
            ${nested_cells_list}    Get From Dictionary    ${cell}    nested_cells
            ${total_rows}    Set Variable    ${0}
            FOR    ${nested_cells}    IN    @{nested_cells_list}
                ${nested_max_rows}    _Html Based Calculate Max Nested Rows    ${nested_cells}
                ${total_rows}    Evaluate    ${total_rows} + ${nested_max_rows}
            END
            IF    ${total_rows} > ${max_rows}
                ${max_rows}    Set Variable    ${total_rows}
            END
        END
    END

    RETURN    ${max_rows}


_Text Based Log Table
    [Arguments]    ${header_structure}    ${max_depth}    ${table_list}

    # Build column info with proper widths (considering both headers and data)
    ${col_info}    _Text Based Build Column Info    ${header_structure}    ${table_list}

    # Generate top border
    ${top_border}    _Text Based Generate Top Border    ${header_structure}    ${max_depth}    ${col_info}

    # Generate header rows
    ${header_rows}    _Text Based Generate Header Rows    ${header_structure}    ${max_depth}    ${col_info}

    # Generate header separator
    ${header_sep}    _Text Based Generate Header Separator    ${col_info}

    # Generate body rows
    ${body_rows}    _Text Based Generate Body Rows    ${table_list}    ${header_structure}    ${col_info}

    # Generate bottom border
    ${bottom_border}    _Text Based Generate Top Border    ${header_structure}    ${max_depth}    ${col_info}

    ${text}    Catenate    SEPARATOR=${\n}    ${top_border}    ${header_rows}    ${header_sep}    ${body_rows}    ${bottom_border}
    RETURN    ${text}


_Text Based Build Column Info
    # PURPOSE: Calculate column widths by scanning both headers AND all data values
    # WHY: Column width must accommodate the widest content (header name or data value)
    # HOW: Extract initial widths from headers, then scan all data and update to maximum
    # CRITICAL: Must scan data recursively to handle nested structures
    # RETURNS: List of column info dicts with {name, width}
    [Arguments]    ${structure}    ${table_list}

    # STEP 1: Get initial widths from header field names
    ${col_info}    _Text Based Extract Leaf Columns    ${structure}

    # STEP 2: Scan all data values and update widths to maximum
    # WHY: Data values might be longer than header names
    FOR    ${row_data}    IN    @{table_list}
        ${cells}    _Html Based Extract Row Cells    ${row_data}    ${structure}
        _Text Based Update Column Widths    ${col_info}    ${cells}    ${0}
    END

    RETURN    ${col_info}


_Text Based Extract Leaf Columns
    [Arguments]    ${structure}

    ${col_info}    Create List

    FOR    ${field}    IN    @{structure}
        IF    ${field}[nested] is None
            ${width}    Evaluate    len('${field}[name]') + 2
            ${info}    Create Dictionary    name=${field}[name]    width=${width}
            Append To List    ${col_info}    ${info}
        ELSE
            ${nested_info}    _Text Based Extract Leaf Columns    ${field}[nested]
            FOR    ${info}    IN    @{nested_info}
                Append To List    ${col_info}    ${info}
            END
        END
    END

    RETURN    ${col_info}


_Text Based Update Column Widths
    # PURPOSE: Recursively scan cell values and update column widths to maximum
    # WHY: Need to ensure all values fit in their columns
    # HOW: For nested cells, recurse into nested_cells. For simple cells, compare value length
    # CRITICAL: Must handle nested structures at any depth
    [Arguments]    ${col_info}    ${cells}    ${col_offset}

    ${current_col}    Set Variable    ${col_offset}

    FOR    ${cell}    IN    @{cells}
        ${is_nested}    Get From Dictionary    ${cell}    is_nested
        ${leaf_count}    Get From Dictionary    ${cell}    leaf_count

        IF    ${is_nested}
            # Nested cell - recurse into all nested items
            ${nested_cells_list}    Get From Dictionary    ${cell}    nested_cells
            FOR    ${nested_cells}    IN    @{nested_cells_list}
                _Text Based Update Column Widths    ${col_info}    ${nested_cells}    ${current_col}
            END
        ELSE
            # Simple cell - check if value is longer than current width
            ${value}    Get From Dictionary    ${cell}    value
            ${value_len}    Evaluate    len('${value}') + 2    # +2 for padding
            ${current_width}    Get From Dictionary    ${col_info}[${current_col}]    width
            IF    ${value_len} > ${current_width}
                Set To Dictionary    ${col_info}[${current_col}]    width=${value_len}
            END
        END

        # Move to next column(s)
        ${current_col}    Evaluate    ${current_col} + ${leaf_count}
    END


_Text Based Generate Header
    [Arguments]    ${header_structure}    ${max_depth}    ${col_info}

    # Build 2D grid for header with rowspan/colspan tracking
    ${grid}    _Text Based Build Header Grid    ${header_structure}    ${max_depth}    ${col_info}

    # Render grid as text lines
    ${lines}    _Text Based Render Header Grid    ${grid}    ${max_depth}    ${col_info}

    ${header}    Catenate    SEPARATOR=${\n}    @{lines}
    RETURN    ${header}


_Text Based Build Header Grid
    [Arguments]    ${header_structure}    ${max_depth}    ${col_info}

    # Initialize grid: max_depth rows x num_cols columns
    ${num_cols}    Get Length    ${col_info}
    ${grid}    Create List
    FOR    ${row}    IN RANGE    ${max_depth}
        ${grid_row}    Create List
        FOR    ${col}    IN RANGE    ${num_cols}
            Append To List    ${grid_row}    ${None}
        END
        Append To List    ${grid}    ${grid_row}
    END

    # Fill grid with cells
    _Text Based Fill Header Grid    ${grid}    ${header_structure}    ${0}    ${0}    ${max_depth}    ${col_info}

    RETURN    ${grid}


_Text Based Fill Header Grid
    [Arguments]    ${grid}    ${structure}    ${row_idx}    ${col_idx}    ${max_depth}    ${col_info}

    ${current_col}    Set Variable    ${col_idx}

    FOR    ${field}    IN    @{structure}
        ${colspan}    _Html Based Count Leaf Columns    ${field}

        IF    ${field}[nested] is not None
            # Nested field: rowspan=1, then recurse
            ${cell}    Create Dictionary    text=${field}[name]    rowspan=${1}    colspan=${colspan}    col_start=${current_col}    start_row=${row_idx}
            Set List Value    ${grid}[${row_idx}]    ${current_col}    ${cell}

            # Mark spanned columns with reference to original cell
            FOR    ${i}    IN RANGE    1    ${colspan}
                ${span_col}    Evaluate    ${current_col} + ${i}
                Set List Value    ${grid}[${row_idx}]    ${span_col}    SPAN
            END

            # Recurse for nested fields
            _Text Based Fill Header Grid    ${grid}    ${field}[nested]    ${row_idx + 1}    ${current_col}    ${max_depth}    ${col_info}
        ELSE
            # Leaf field: rowspan to bottom
            ${rowspan}    Evaluate    ${max_depth} - ${row_idx}
            ${cell}    Create Dictionary    text=${field}[name]    rowspan=${rowspan}    colspan=${colspan}    col_start=${current_col}    start_row=${row_idx}
            Set List Value    ${grid}[${row_idx}]    ${current_col}    ${cell}

            # Mark spanned rows with reference to original cell
            FOR    ${r}    IN RANGE    ${row_idx + 1}    ${max_depth}
                Set List Value    ${grid}[${r}]    ${current_col}    ${cell}
            END
            # Mark spanned columns
            FOR    ${i}    IN RANGE    1    ${colspan}
                ${span_col}    Evaluate    ${current_col} + ${i}
                FOR    ${r}    IN RANGE    ${row_idx}    ${max_depth}
                    Set List Value    ${grid}[${r}]    ${span_col}    SPAN
                END
            END
        END

        ${current_col}    Evaluate    ${current_col} + ${colspan}
    END


_Text Based Render Header Grid
    [Arguments]    ${grid}    ${max_depth}    ${col_info}

    ${lines}    Create List
    ${content_rows}    Create List
    
    # First pass: identify rows with content
    FOR    ${row_idx}    IN RANGE    ${max_depth}
        ${row}    Set Variable    ${grid}[${row_idx}]
        ${has_content}    Set Variable    ${False}
        FOR    ${cell}    IN    @{row}
            ${is_span}    Run Keyword And Return Status    Should Be Equal    ${cell}    SPAN
            IF    ${is_span}
                CONTINUE
            END
            ${is_none}    Evaluate    $cell is None
            IF    ${is_none}
                CONTINUE
            END
            ${start_row}    Get From Dictionary    ${cell}    start_row
            IF    ${start_row} == ${row_idx}
                ${has_content}    Set Variable    ${True}
                BREAK
            END
        END
        IF    ${has_content}
            Append To List    ${content_rows}    ${row_idx}
        END
    END
    
    # Second pass: render content rows with separators
    ${num_content_rows}    Get Length    ${content_rows}
    FOR    ${i}    IN RANGE    ${num_content_rows}
        ${row_idx}    Set Variable    ${content_rows}[${i}]
        ${row}    Set Variable    ${grid}[${row_idx}]
        ${line}    _Text Based Render Header Grid Row    ${row}    ${row_idx}    ${grid}    ${col_info}
        Append To List    ${lines}    ${line}
        
        # Add separator between rows (not after last)
        IF    ${i} < ${num_content_rows} - 1
            ${next_row_idx}    Set Variable    ${content_rows}[${i + 1}]
            ${next_row}    Set Variable    ${grid}[${next_row_idx}]
            ${sep}    _Text Based Generate Row Separator    ${row}    ${next_row}    ${col_info}
            Append To List    ${lines}    ${sep}
        END
    END

    RETURN    ${lines}


_Text Based Generate Row Separator
    # PURPOSE: Generate separator line between table rows with smart junction characters
    # WHY: Need to show borders between rows, but NOT where cells span down (rowspan)
    # HOW: Compare current and next row cells - if same cell object, use space (no border)
    # CRITICAL: Uses object identity ($curr_cell is $next_cell) to detect rowspan
    # SMART JUNCTIONS: Use '+' if adjacent sides have dashes, '|' if both sides have spaces
    # RETURNS: Separator line string
    [Arguments]    ${current_row}    ${next_row}    ${col_info}

    ${parts}    Create List
    ${num_cols}    Get Length    ${col_info}

    # STEP 1: Build border segments for each column
    FOR    ${col_idx}    IN RANGE    ${num_cols}
        ${curr_cell}    Set Variable    ${current_row}[${col_idx}]
        ${next_cell}    Set Variable    ${next_row}[${col_idx}]

        ${curr_is_span}    Run Keyword And Return Status    Should Be Equal    ${curr_cell}    SPAN
        ${next_is_span}    Run Keyword And Return Status    Should Be Equal    ${next_cell}    SPAN
        ${curr_is_none}    Evaluate    $curr_cell is None
        ${next_is_none}    Evaluate    $next_cell is None

        ${width}    Get From Dictionary    ${col_info}[${col_idx}]    width

        # Check if cell continues from current row to next row (rowspan detection)
        ${is_continuing}    Set Variable    ${False}
        IF    not ${curr_is_span} and not ${next_is_span} and not ${curr_is_none} and not ${next_is_none}
            # Both are actual cells - check if they're the SAME cell object (rowspan)
            # WHY: When filling grid, we store same cell reference in all rows it spans
            ${is_same}    Evaluate    $curr_cell is $next_cell
            IF    ${is_same}
                ${is_continuing}    Set Variable    ${True}
            END
        END

        # If cell is continuing (rowspan), use space; otherwise use dash
        IF    ${is_continuing}
            ${part}    Evaluate    ' ' * ${width}
        ELSE
            ${part}    Evaluate    '-' * ${width}
        END

        Append To List    ${parts}    ${part}
    END

    # STEP 2: Build separator with smart junction characters
    # WHY: '+' looks wrong where there are no horizontal lines (vertical cell merging)
    ${sep}    Set Variable    ${EMPTY}
    ${num_parts}    Get Length    ${parts}
    FOR    ${i}    IN RANGE    ${num_parts}
        ${part}    Set Variable    ${parts}[${i}]
        
        # Add left junction
        IF    ${i} == 0
            # First column - check if it has dashes (horizontal line)
            ${has_dash}    Evaluate    '-' in '''${part}'''
            IF    ${has_dash}
                ${sep}    Set Variable    +${part}    # Use '+' if there's a horizontal line
            ELSE
                ${sep}    Set Variable    |${part}    # Use '|' if no horizontal line (cell spans down)
            END
        ELSE
            # Inner junction - check both left and right sides
            ${prev_part}    Set Variable    ${parts}[${i - 1}]
            ${has_left_dash}    Evaluate    '-' in '''${prev_part}'''
            ${has_right_dash}    Evaluate    '-' in '''${part}'''
            
            # Use '+' if at least one side has dashes, '|' if both sides are spaces
            IF    ${has_left_dash} or ${has_right_dash}
                ${sep}    Set Variable    ${sep}+${part}
            ELSE
                ${sep}    Set Variable    ${sep}|${part}
            END
        END
    END
    
    # Add right junction - check if last part has dashes
    ${last_part}    Set Variable    ${parts}[${num_parts - 1}]
    ${has_dash}    Evaluate    '-' in '''${last_part}'''
    IF    ${has_dash}
        ${sep}    Set Variable    ${sep}+
    ELSE
        ${sep}    Set Variable    ${sep}|
    END
    
    RETURN    ${sep}


_Text Based Render Header Grid Row
    [Arguments]    ${row}    ${row_idx}    ${grid}    ${col_info}

    ${parts}    Create List
    ${num_cols}    Get Length    ${col_info}

    FOR    ${col_idx}    IN RANGE    ${num_cols}
        ${cell}    Set Variable    ${row}[${col_idx}]
        ${is_span}    Run Keyword And Return Status    Should Be Equal    ${cell}    SPAN
        ${is_none}    Evaluate    $cell is None

        IF    ${is_span}
            # Skip - colspan span
            CONTINUE
        ELSE IF    ${is_none}
            # Empty cell
            ${width}    Get From Dictionary    ${col_info}[${col_idx}]    width
            ${spaces}    Evaluate    ' ' * ${width}
            Append To List    ${parts}    ${spaces}
        ELSE
            # Actual cell - determine if we show text based on vertical position
            ${text}    Get From Dictionary    ${cell}    text
            ${colspan}    Get From Dictionary    ${cell}    colspan
            ${col_start}    Get From Dictionary    ${cell}    col_start
            ${rowspan}    Get From Dictionary    ${cell}    rowspan
            ${start_row}    Get From Dictionary    ${cell}    start_row

            # Calculate total width
            ${total_width}    Set Variable    ${0}
            FOR    ${i}    IN RANGE    ${colspan}
                ${idx}    Evaluate    ${col_start} + ${i}
                ${w}    Get From Dictionary    ${col_info}[${idx}]    width
                ${total_width}    Evaluate    ${total_width} + ${w} + 1
            END
            ${total_width}    Evaluate    ${total_width} - 1

            # Show text only in first row of this cell's rowspan
            ${relative_row}    Evaluate    ${row_idx} - ${start_row}

            IF    ${relative_row} == 0
                ${display_text}    Set Variable    ${text}
            ELSE
                ${display_text}    Set Variable    ${EMPTY}
            END

            # Center text horizontally
            ${text_len}    Evaluate    len('${display_text}')
            ${padding}    Evaluate    ${total_width} - ${text_len}
            ${left_pad}    Evaluate    ${padding} // 2
            ${right_pad}    Evaluate    ${padding} - ${left_pad}
            ${left_spaces}    Evaluate    ' ' * ${left_pad}
            ${right_spaces}    Evaluate    ' ' * ${right_pad}
            ${padded_text}    Set Variable    ${left_spaces}${display_text}${right_spaces}
            Append To List    ${parts}    ${padded_text}
        END
    END

    ${line}    Catenate    SEPARATOR=|    @{parts}
    ${line}    Set Variable    |${line}|

    RETURN    ${line}


_Text Based Generate Header Rows
    [Arguments]    ${header_structure}    ${max_depth}    ${col_info}

    ${header}    _Text Based Generate Header    ${header_structure}    ${max_depth}    ${col_info}
    RETURN    ${header}


_Text Based Generate Top Border
    [Arguments]    ${header_structure}    ${max_depth}    ${col_info}

    ${parts}    Create List
    FOR    ${col}    IN    @{col_info}
        ${width}    Get From Dictionary    ${col}    width
        ${part}    Evaluate    '-' * ${width}
        Append To List    ${parts}    ${part}
    END
    ${border}    Catenate    SEPARATOR=+    @{parts}
    ${border}    Set Variable    +${border}+
    RETURN    ${border}


_Text Based Generate Header Separator
    [Arguments]    ${col_info}

    ${parts}    Create List
    FOR    ${col}    IN    @{col_info}
        ${width}    Get From Dictionary    ${col}    width
        ${part}    Evaluate    '=' * ${width}
        Append To List    ${parts}    ${part}
    END
    ${border}    Catenate    SEPARATOR=+    @{parts}
    ${border}    Set Variable    +${border}+
    RETURN    ${border}


_Text Based Generate Body Rows
    [Arguments]    ${table_list}    ${header_structure}    ${col_info}

    ${all_lines}    Create List
    ${num_data_rows}    Get Length    ${table_list}

    FOR    ${data_row_idx}    IN RANGE    ${num_data_rows}
        ${row_data}    Set Variable    ${table_list}[${data_row_idx}]
        
        # Extract cells for this data row
        ${cells}    _Html Based Extract Row Cells    ${row_data}    ${header_structure}
        
        # Calculate how many text rows needed
        ${num_text_rows}    _Html Based Calculate Max Nested Rows    ${cells}
        
        # Build grid for this data row
        ${grid}    _Text Based Build Body Grid    ${cells}    ${num_text_rows}    ${col_info}
        
        # Render grid rows
        ${row_lines}    _Text Based Render Body Grid    ${grid}    ${num_text_rows}    ${col_info}
        
        FOR    ${line}    IN    @{row_lines}
            Append To List    ${all_lines}    ${line}
        END
        
        # Add separator between data rows (not after last)
        IF    ${data_row_idx} < ${num_data_rows} - 1
            ${sep}    _Text Based Generate Data Row Separator    ${col_info}
            Append To List    ${all_lines}    ${sep}
        END
    END

    ${body}    Catenate    SEPARATOR=${\n}    @{all_lines}
    RETURN    ${body}


_Text Based Build Body Grid
    [Arguments]    ${cells}    ${num_text_rows}    ${col_info}

    ${num_cols}    Get Length    ${col_info}
    ${grid}    Create List
    
    # Initialize grid
    FOR    ${row}    IN RANGE    ${num_text_rows}
        ${grid_row}    Create List
        FOR    ${col}    IN RANGE    ${num_cols}
            Append To List    ${grid_row}    ${None}
        END
        Append To List    ${grid}    ${grid_row}
    END

    # Fill grid
    _Text Based Fill Body Grid    ${grid}    ${cells}    ${0}    ${0}    ${num_text_rows}

    RETURN    ${grid}


_Text Based Fill Body Grid
    # PURPOSE: Recursively fill grid with cell data, handling nested structures
    # WHY: Nested cells must be distributed across multiple rows
    # HOW: For nested cells, process each nested item sequentially with row offset accumulation
    #      For non-nested cells, span all rows at current nesting level
    # CRITICAL: Store same cell object in all rows it spans (enables rowspan detection)
    [Arguments]    ${grid}    ${cells}    ${row_offset}    ${col_offset}    ${num_text_rows}

    ${current_col}    Set Variable    ${col_offset}

    FOR    ${cell}    IN    @{cells}
        ${is_nested}    Get From Dictionary    ${cell}    is_nested
        ${leaf_count}    Get From Dictionary    ${cell}    leaf_count

        IF    ${is_nested}
            # Nested cell - process each nested item sequentially
            # WHY: Each nested item occupies a contiguous block of rows
            # EXAMPLE: 2 nested items with 2 rows each → rows 0-1 for item1, rows 2-3 for item2
            ${nested_cells_list}    Get From Dictionary    ${cell}    nested_cells
            ${current_row}    Set Variable    ${row_offset}
            
            FOR    ${nested_cells}    IN    @{nested_cells_list}
                # Calculate how many rows this nested item needs
                ${nested_rows}    _Html Based Calculate Max Nested Rows    ${nested_cells}
                # Recursively fill grid for this nested item
                _Text Based Fill Body Grid    ${grid}    ${nested_cells}    ${current_row}    ${current_col}    ${nested_rows}
                # Move to next row block
                ${current_row}    Evaluate    ${current_row} + ${nested_rows}
            END
        ELSE
            # Non-nested cell - fill with value spanning all rows at this level
            # WHY: Non-nested cells must span all rows generated by sibling nested cells
            ${value}    Get From Dictionary    ${cell}    value
            ${cell_info}    Create Dictionary    value=${value}    rowspan=${num_text_rows}    colspan=${leaf_count}    col_start=${current_col}    start_row=${row_offset}
            
            # CRITICAL: Store same cell reference in all rows it spans
            # WHY: Enables rowspan detection via object identity comparison
            ${end_row}    Evaluate    ${row_offset} + ${num_text_rows}
            FOR    ${r}    IN RANGE    ${row_offset}    ${end_row}
                Set List Value    ${grid}[${r}]    ${current_col}    ${cell_info}
            END
            
            # Mark colspan spans with "SPAN" string
            FOR    ${c}    IN RANGE    1    ${leaf_count}
                ${span_col}    Evaluate    ${current_col} + ${c}
                FOR    ${r}    IN RANGE    ${row_offset}    ${end_row}
                    Set List Value    ${grid}[${r}]    ${span_col}    SPAN
                END
            END
        END

        # Move to next column(s)
        ${current_col}    Evaluate    ${current_col} + ${leaf_count}
    END


_Text Based Render Body Grid
    [Arguments]    ${grid}    ${num_text_rows}    ${col_info}

    ${lines}    Create List

    FOR    ${row_idx}    IN RANGE    ${num_text_rows}
        ${row}    Set Variable    ${grid}[${row_idx}]
        ${line}    _Text Based Render Body Grid Row    ${row}    ${row_idx}    ${col_info}
        Append To List    ${lines}    ${line}
        
        # Add separator between text rows (not after last)
        IF    ${row_idx} < ${num_text_rows} - 1
            ${next_row}    Set Variable    ${grid}[${row_idx + 1}]
            ${sep}    _Text Based Generate Row Separator    ${row}    ${next_row}    ${col_info}
            Append To List    ${lines}    ${sep}
        END
    END

    RETURN    ${lines}


_Text Based Render Body Grid Row
    # PURPOSE: Render one row of the body grid as a text line
    # WHY: Convert grid representation to actual ASCII table line
    # HOW: For each column, output cell value (centered) or skip if SPAN
    # CRITICAL: Show text only in FIRST row of cell's span (relative_row == 0)
    # RETURNS: Formatted text line with | separators
    [Arguments]    ${row}    ${row_idx}    ${col_info}

    ${parts}    Create List
    ${num_cols}    Get Length    ${col_info}

    FOR    ${col_idx}    IN RANGE    ${num_cols}
        ${cell}    Set Variable    ${row}[${col_idx}]
        ${is_span}    Run Keyword And Return Status    Should Be Equal    ${cell}    SPAN
        ${is_none}    Evaluate    $cell is None

        IF    ${is_span}
            # Skip - this is part of a colspan
            CONTINUE
        ELSE IF    ${is_none}
            # Empty cell - fill with spaces
            ${width}    Get From Dictionary    ${col_info}[${col_idx}]    width
            ${spaces}    Evaluate    ' ' * ${width}
            Append To List    ${parts}    ${spaces}
        ELSE
            # Actual cell - determine if we show text based on vertical position
            ${value}    Get From Dictionary    ${cell}    value
            ${colspan}    Get From Dictionary    ${cell}    colspan
            ${col_start}    Get From Dictionary    ${cell}    col_start
            ${start_row}    Get From Dictionary    ${cell}    start_row

            # Calculate total width (sum of all spanned columns + separators)
            ${total_width}    Set Variable    ${0}
            FOR    ${i}    IN RANGE    ${colspan}
                ${idx}    Evaluate    ${col_start} + ${i}
                ${w}    Get From Dictionary    ${col_info}[${idx}]    width
                ${total_width}    Evaluate    ${total_width} + ${w} + 1
            END
            ${total_width}    Evaluate    ${total_width} - 1

            # CRITICAL: Show value only in first row of this cell's rowspan
            # WHY: Text should appear at top of cell, not middle or repeated
            ${relative_row}    Evaluate    ${row_idx} - ${start_row}
            IF    ${relative_row} == 0
                ${display_text}    Set Variable    ${value}
            ELSE
                ${display_text}    Set Variable    ${EMPTY}
            END

            # Center text horizontally
            ${text_len}    Evaluate    len('${display_text}')
            ${padding}    Evaluate    ${total_width} - ${text_len}
            ${left_pad}    Evaluate    ${padding} // 2
            ${right_pad}    Evaluate    ${padding} - ${left_pad}
            ${left_spaces}    Evaluate    ' ' * ${left_pad}
            ${right_spaces}    Evaluate    ' ' * ${right_pad}
            ${padded_text}    Set Variable    ${left_spaces}${display_text}${right_spaces}
            Append To List    ${parts}    ${padded_text}
        END
    END

    # Join parts with | separator and add outer borders
    ${line}    Catenate    SEPARATOR=|    @{parts}
    ${line}    Set Variable    |${line}|
    RETURN    ${line}


_Text Based Generate Data Row Separator
    [Arguments]    ${col_info}

    ${parts}    Create List
    FOR    ${col}    IN    @{col_info}
        ${width}    Get From Dictionary    ${col}    width
        ${part}    Evaluate    '-' * ${width}
        Append To List    ${parts}    ${part}
    END
    ${sep}    Catenate    SEPARATOR=+    @{parts}
    ${sep}    Set Variable    +${sep}+
    RETURN    ${sep}


_Text Based Render Header Row
    [Arguments]    ${cells}    ${level}    ${max_depth}

    ${parts}    Create List

    FOR    ${cell}    IN    @{cells}
        ${text}    Get From Dictionary    ${cell}    text
        ${width}    Get From Dictionary    ${cell}    width
        ${text_len}    Evaluate    len('${text}')
        ${padding}    Evaluate    ${width} - ${text_len}
        ${left_pad}    Evaluate    ${padding} // 2
        ${right_pad}    Evaluate    ${padding} - ${left_pad}
        ${left_spaces}    Evaluate    ' ' * ${left_pad}
        ${right_spaces}    Evaluate    ' ' * ${right_pad}
        ${padded_text}    Set Variable    ${left_spaces}${text}${right_spaces}
        Append To List    ${parts}    ${padded_text}
    END

    ${row}    Catenate    SEPARATOR=|    @{parts}
    ${row}    Set Variable    |${row}|

    RETURN    ${row}


_Text Based Generate Header Level
    [Arguments]    ${structure}    ${target_level}    ${current_level}    ${max_depth}    ${col_info}

    ${cells}    Create List
    ${col_idx}    Set Variable    ${0}

    FOR    ${field}    IN    @{structure}
        IF    ${current_level} == ${target_level} + 1
            ${colspan}    _Html Based Count Leaf Columns    ${field}
            IF    ${field}[nested] is not None
                ${rowspan}    Set Variable    ${1}
            ELSE
                ${rowspan}    Evaluate    ${max_depth} - ${current_level} + 1
            END

            # Calculate total width for this cell
            ${total_width}    Set Variable    ${0}
            FOR    ${i}    IN RANGE    ${colspan}
                ${idx}    Evaluate    ${col_idx} + ${i}
                ${total_width}    Evaluate    ${total_width} + ${col_info}[${idx}][width] + 1
            END
            ${total_width}    Evaluate    ${total_width} - 1

            ${cell}    Create Dictionary    text=${field}[name]    width=${total_width}    rowspan=${rowspan}    colspan=${colspan}
            Append To List    ${cells}    ${cell}
            ${col_idx}    Evaluate    ${col_idx} + ${colspan}
        ELSE IF    ${field}[nested] is not None and ${current_level} < ${target_level} + 1
            ${nested_cells}    _Text Based Generate Header Level    ${field}[nested]    ${target_level}    ${current_level + 1}    ${max_depth}    ${col_info}
            FOR    ${cell}    IN    @{nested_cells}
                Append To List    ${cells}    ${cell}
            END
            ${colspan}    _Html Based Count Leaf Columns    ${field}
            ${col_idx}    Evaluate    ${col_idx} + ${colspan}
        END
    END

    RETURN    ${cells}



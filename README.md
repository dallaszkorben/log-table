# Robot Framework Table Generator

A comprehensive table generation library for Robot Framework that creates both HTML and ASCII tables from nested dictionary data structures.

## Features

- **Dual Output Formats**: Generate both HTML (for reports) and ASCII (for console) tables
- **Arbitrary Nesting**: Handle 1-4+ levels of nested data structures
- **Smart Formatting**: Automatic column width calculation and rowspan/colspan handling
- **Python & Robot Framework**: Available as both Python library and Robot Framework resource
- **Performance Optimized**: 53% code reduction in Python implementation

## Quick Start

### Robot Framework Usage

```robot
*** Settings ***
Library    log-table.py

*** Test Cases ***
Generate Table Example
    ${data}    Create List
    ...    &{field_1=value1    field_2=${nested_data}}
    Log Table    ${data}    console=${True}
```

### Python Usage

```python
from log_table import LogTable

generator = LogTable()
generator.log_table(data_list, console=True)
```

## File Structure

```
├── log-table.py           # Python implementation (recommended)
├── log-table.resource     # Robot Framework implementation  
├── test-log-table.robot   # Test cases for all nesting levels
└── .amazonq/              # Documentation and context files
    ├── HTML_TABLE_GENERATION_SUMMARY.md
    ├── PYTHON_TRANSLATION_SUMMARY.md
    ├── ROBOT_TO_PYTHON_PATTERNS.md
    └── TEXT_TABLE_GENERATION_SUMMARY.md
```

## Input Data Examples

### 1-Level (Flat Data)
```robot
&{row1}    Create Dictionary    field_1=1    field_2=2    field_3=3    field_4=A    field_5=AA    field_6=AAA
&{row2}    Create Dictionary    field_1=4    field_2=5    field_3=6    field_4=B    field_5=BB    field_6=BBB
&{row3}    Create Dictionary    field_1=7    field_5=CC    field_6=CCC
&{row4}    Create Dictionary    field_1=10    field_2=11    field_3=12    field_4=D    field_5=DD    field_6=DDD
&{row5}    Create Dictionary    field_1=13    field_2=14    field_3=15    field_4=E    field_5=EE    field_6=EEE
@{table_list}    Create List    ${row1}    ${row2}    ${row3}    ${row4}    ${row5}
```

### 2-Level (Nested Data)
```robot
&{row1_nested1}    Create Dictionary    field_3_1=value_1_3_1_1    field_3_2=value_1_3_1_2
&{row1_nested2}    Create Dictionary    field_3_1=value_1_3_2_1    field_3_2=value_1_3_2_2    field_3_3=value_1_3_2_3
@{row1_field3}    Create List    ${row1_nested1}    ${row1_nested2}
&{row1}    Create Dictionary    field_1=value_1_1    field_2=value_1_2    field_3=${row1_field3}

&{row2_nested1}    Create Dictionary    field_3_1=value_2_3_1_1    field_3_2=value_1_3_1_2
@{row2_field3}    Create List    ${row2_nested1}
&{row2}    Create Dictionary    field_1=value_2_1    field_2=value_2_2    field_3=${row2_field3}
@{table_list}    Create List    ${row1}    ${row2}
```

### 3-Level (Deep Nesting)
```robot
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
@{table_list}    Create List    ${row1}    ${row2}
```

### 4-Level (Maximum Nesting)
```robot
&{r1_s1_n1}    Create Dictionary    sub_1-1=1_4_1_1-1_A    sub_1-2=1_4_1_1-1_B
&{r1_s1_n2}    Create Dictionary    sub_1-1=1_4_1_1-2_C    sub_1-2=1_4_1_1_2_D
@{r1_s1_list}    Create List    ${r1_s1_n1}    ${r1_s1_n2}

&{r1_sf1_n1}    Create Dictionary    sub_1=${r1_s1_list}    sub_2=1_4_1_1

&{r1_s1_n3}    Create Dictionary    sub_1-1=1_4_1_2-1_A    sub_1-2=1_4_1_2-1_B
&{r1_s1_n4}    Create Dictionary    sub_1-1=1_4_1_2_2_D    sub_1-2=1_4_1_2_2_E
@{r1_s1_list2}    Create List    ${r1_s1_n3}    ${r1_s1_n4}

&{r1_sf1_n2}    Create Dictionary    sub_1=${r1_s1_list2}    sub_2=1_4_1_2

@{r1_sf1_list}    Create List    ${r1_sf1_n1}    ${r1_sf1_n2}

&{r1_f4_n1}    Create Dictionary    sub-4-field_1=${r1_sf1_list}    sub-4-field_2=1_4_1

@{r1_field4}    Create List    ${r1_f4_n1}

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
```

## Output Examples

### 1-Level (Flat Data)
```
+-----------+-----------+---------+---------+---------+---------+
|  field_1  |  field_2  | field_3 | field_4 | field_5 | field_6 |
+===============================================================+ 
|     1     |     2     |    3    |    A    |    AA   |   AAA   |
+-----------+-----------+---------+---------+---------+---------+
|     4     |     5     |    6    |    B    |    BB   |   BBB   |
+-----------+-----------+---------+---------+---------+---------+
|     7     |           |         |         |    CC   |   CCC   |
+-----------+-----------+---------+---------+---------+---------+
|     10    |     11    |    12   |    D    |    DD   |   DDD   |
+-----------+-----------+---------+---------+---------+---------+
|     13    |     14    |    15   |    E    |    EE   |   EEE   |
+-----------+-----------+---------+---------+---------+---------+
```

### 2-Level (Nested Data)
```
+-----------+-----------+-----------------------------------------------+
|           |           |                   field_3                     |
|  field_1  |  field_2  +---------------+---------------+---------------+
|           |           |   field_3_1   |   field_3_2   |   field_3_3   |
+=======================================================================+ 
|           |           | value_1_3_1_1 | value_1_3_1_2 |               |
| value_1_1 | value_1_2 +---------------+---------------+---------------+
|           |           | value_1_3_2_1 | value_1_3_2_2 | value_1_3_2_3 |
+-----------+-----------+---------------+---------------+---------------+
| value_2_1 | value_2_2 | value_2_3_1_1 | value_1_3_1_2 |               |
+-----------+-----------+---------------+---------------+---------------+
```

### 3-Level (Deep Nesting)
```
+-----------+-----------+---------+-----------------------------------+---------+---------+
|           |           |         |              field_4              |         |         |
|  field_1  |  field_2  | field_3 +-------------------+---------------+ field_5 | field_6 |
|           |           |         |   sub-4-field_1   | sub-4-field_2 |         |         |
|           |           |         +-------------------|               |         |         |
|           |           |         |  sub_1  |  sub_2  |               |         |         |
+===========+===========+=========+=========+=========+===============+=========+=========+ 
|    1_1    |    1_2    |   1_3   | 1_4_1_A | 1_4_1_B |      1_4_1    |   1_5   |  1_6    |
|           |           |         +---------+---------+               |         |         |
|           |           |         | 1_4_1_C | 1_4_1_D |               |         |         |
|           |           |         +---------+---------+---------------+         |         |
|           |           |         | 1_4_2_A | 1_4_2_B |               |         |         |
|           |           |         +---------+---------+      1_4_2    |         |         |
|           |           |         | 1_4_2_D | 1_4_2_E |               |         |         |
+-----------+-----------+---------+---------+---------+---------------+---------+---------+
|    2_1    |    2_2    |   2_3   | 2_4_1_A | 2_4_1_B |      2_4_1    |   2_5   |  2_6    |
|           |           |         +---------+---------+               |         |         |
|           |           |         | 2_4_1_C | 2_4_1_D |               |         |         |
|           |           |         +---------+---------+---------------+         |         |
|           |           |         | 2_4_2_A | 2_4_2_B |               |         |         |
|           |           |         +---------+---------+      2_4_2    |         |         |
|           |           |         | 2_4_2_D | 2_4_2_E |               |         |         |
+-----------+-----------+---------+---------+---------+---------------+---------+---------+
```

### 4-Level (Maximum Nesting)
```
+-----------+-----------+---------+-------------------------------------------------------------+---------+---------+
|           |           |         |                               field_4                       |         |         |
|  field_1  |  field_2  | field_3 +---------------------------------------------+---------------+ field_5 | field_6 |
|           |           |         |        sub-4-field_1                        | sub-4-field_2 |         |         |
|           |           |         +-----------------------------+---------------+               |         |         |
|           |           |         |        sub_1                |     sub_2     |               |         |         |
|           |           |         +-------------+---------------+               |               |         |         |
|           |           |         |   sub_1-1   |    sub_1-2    |               |               |         |         |
+===================================================================================================================+
|    1_1    |    1_2    |   1_3   | 1_4_1_1-1_A |  1_4_1_1-1_B  |   1_4_1_1     |      1_4_1    |   1_5   |  1_6    |
|           |           |         +-------------+---------------+               |               |         |         |
|           |           |         | 1_4_1_1-2_C |  1_4_1_1_2_D  |               |               |         |         |
|           |           |         +-------------+---------------+---------------+               |         |         |
|           |           |         | 1_4_1_2-1_A |  1_4_1_2-1_B  |               |               |         |         |
|           |           |         +-------------+---------------+   1_4_1_2     |               |         |         |
|           |           |         | 1_4_1_2_2_D |  1_4_1_2_2_E  |               |               |         |         |
+-----------+-----------+---------+-------------+---------------+---------------+---------------+---------+---------+
|    2_1    |    2_2    |   2_3   | 2_4_1_1-1_A |  2_4_1_1-1_B  |   2_4_1_1     |      2_4_1    |   2_5   |  2_6    |
|           |           |         +-------------+---------------+               |               |         |         |
|           |           |         | 2_4_1_1-2_C |  2_4_1_1_2_D  |               |               |         |         |
|           |           |         +-------------+---------------+---------------+               |         |         |
|           |           |         | 2_4_1_2-1_A |  2_4_1_2-1_B  |               |               |         |         |
|           |           |         +-------------+---------------+   2_4_1_2     |               |         |         |
|           |           |         | 2_4_1_2_2_D |  2_4_1_2_2_E  |               |               |         |         |
+-----------+-----------+---------+-------------+---------------+---------------+---------------+---------+---------+
```

## Supported Data Structures

### 1-Level (Flat)
```python
[{"field_1": "1", "field_2": "2", "field_3": "3"}]
```

### 2-Level (Nested)
```python
[{"field_1": "value_1_1", "field_2": "value_1_2", 
  "field_3": [{"field_3_1": "value_1_3_1_1", "field_3_2": "value_1_3_1_2"}]}]
```

### 3-Level (Deep Nesting)
```python
[{"field_1": "1_1", "field_4": [{"sub-4-field_1": [{"sub_1": "1_4_1_A", "sub_2": "1_4_1_B"}]}]}]
```

## Key Algorithms

- **Recursive Structure Analysis**: Preserves nesting without flattening
- **Grid-Based Rendering**: 2D grid approach for both headers and body
- **Smart Junction Characters**: `+` vs `|` based on adjacent borders
- **Column Width Optimization**: Scans both headers and data for optimal sizing
- **Rowspan-Aware Borders**: Removes horizontal lines where cells span vertically

## Testing

Run all test cases:
```bash
robot test-log-table.robot
```

Test coverage includes:
- ✅ 1-level flat data (6 fields, 5 rows)
- ✅ 2-level nested data
- ✅ 3-level nested data  
- ✅ 4-level nested data

## Performance

| Implementation | Lines of Code | Performance |
|----------------|---------------|-------------|
| Robot Framework | 1,184 lines | Baseline |
| Python | 551 lines | 53% reduction |

## Documentation

Comprehensive documentation available in `.amazonq/`:
- **HTML Generation**: Complete algorithm documentation
- **Python Translation**: Translation patterns and benefits
- **Text Generation**: ASCII table rendering details
- **Robot Framework Patterns**: Best practices and idioms

## Requirements

- Robot Framework 4.0+
- Python 3.7+

## License

Open source - see project documentation for details.

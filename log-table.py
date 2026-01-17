"""
Table generation library for Robot Framework.
Generates HTML and text-based tables from nested dictionary structures.
"""

from robot.api.deco import keyword, library
from robot.api import logger


@library(scope='GLOBAL', auto_keywords=False)
class log_table:
    """Library for generating tables from nested dictionaries."""

    @keyword
    def log_table(self, table_list, console=True):
        """
        Generates and logs tables (HTML and optionally text-based) from a list of dictionaries.
        
        Args:
            table_list: List of dictionaries where values can be strings or lists of dictionaries
            console: If True, generates and logs text-based table to console. Default: True
        """
        # STEP 1: Analyze the table structure
        header_structure, max_depth = self._analyze_table_structure(table_list)
        
        # STEP 2: Generate HTML table
        html = self._generate_html_table(table_list, header_structure, max_depth)
        logger.info(html, html=True)
        
        # STEP 3: Generate text-based table (optional)
        if console:
            text = self._generate_text_table(header_structure, max_depth, table_list)
            logger.info(f"\n{text}", also_console=True)
    
    def _analyze_table_structure(self, table_list):
        """Analyze all data rows to build a unified header structure."""
        header_structure = []
        max_depth = 1
        
        for row in table_list:
            current_structure = self._extract_structure(row, 1)
            header_structure = self._merge_structures(header_structure, current_structure)
            row_depth = self._calculate_depth(current_structure)
            if row_depth > max_depth:
                max_depth = row_depth
        
        return header_structure, max_depth
    
    def _extract_structure(self, data, depth):
        """Recursively extract field structure from a dictionary."""
        structure = []
        
        for key, value in data.items():
            if isinstance(value, list):
                # Nested data
                nested_structure = []
                for item in value:
                    item_structure = self._extract_structure(item, depth + 1)
                    nested_structure = self._merge_structures(nested_structure, item_structure)
                field_info = {'name': key, 'nested': nested_structure, 'depth': depth}
            else:
                # Simple data
                field_info = {'name': key, 'nested': None, 'depth': depth}
            
            structure.append(field_info)
        
        return structure
    
    def _merge_structures(self, base_structure, new_structure):
        """Merge two structure lists to create a unified structure."""
        if not base_structure:
            return new_structure
        
        merged = []
        
        # Process each field from new_structure
        for new_field in new_structure:
            found = False
            merged_field = None
            
            for base_field in base_structure:
                if base_field['name'] == new_field['name']:
                    found = True
                    if new_field['nested'] is not None and base_field['nested'] is not None:
                        merged_nested = self._merge_structures(base_field['nested'], new_field['nested'])
                        merged_field = {'name': base_field['name'], 'nested': merged_nested, 'depth': base_field['depth']}
                    elif new_field['nested'] is not None:
                        merged_field = new_field
                    else:
                        merged_field = base_field
                    break
            
            if not found:
                merged.append(new_field)
            elif merged_field is not None:
                if not any(item['name'] == merged_field['name'] for item in merged):
                    merged.append(merged_field)
        
        # Add fields from base_structure that weren't in new_structure
        for base_field in base_structure:
            if not any(item['name'] == base_field['name'] for item in merged):
                merged.append(base_field)
        
        return merged
    
    def _calculate_depth(self, structure):
        """Calculate maximum nesting depth in the structure."""
        max_depth = 1
        
        for field in structure:
            if field['nested'] is not None:
                nested_depth = self._calculate_depth(field['nested'])
                total_depth = field['depth'] + nested_depth
                if total_depth > max_depth:
                    max_depth = total_depth
        
        return max_depth
    
    def _generate_html_table(self, table_list, header_structure, max_depth):
        """Generate HTML table with CSS classes."""
        # CSS styles
        style = '<style>.th{background-color:#d3d3d3;text-align:center}.td{background-color:#ffffe0;text-align:center}</style>'
        html = f'{style}<table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">\n'
        
        # Generate headers
        html += self._generate_html_headers(header_structure, max_depth)
        
        # Generate data rows
        for row_data in table_list:
            html += self._generate_html_data_row(row_data, header_structure)
        
        html += '</table>'
        return html
    
    def _generate_html_headers(self, header_structure, max_depth):
        """Generate HTML header rows."""
        html = ''
        for level in range(max_depth):
            html += '<tr>'
            html += self._generate_html_header_level(header_structure, level, 1, max_depth)
            html += '</tr>\n'
        return html
    
    def _generate_html_header_level(self, structure, target_level, current_level, max_depth):
        """Generate HTML headers at specific level."""
        html = ''
        
        for field in structure:
            if current_level == target_level + 1:
                colspan = self._count_leaf_columns(field)
                rowspan = 1 if field['nested'] is not None else max_depth - current_level + 1
                html += f'<th rowspan="{rowspan}" colspan="{colspan}" class="th">{field["name"]}</th>'
            elif field['nested'] is not None and current_level < target_level + 1:
                html += self._generate_html_header_level(field['nested'], target_level, current_level + 1, max_depth)
        
        return html
    
    def _count_leaf_columns(self, field):
        """Count how many leaf columns a field spans."""
        if field['nested'] is None:
            return 1
        
        count = 0
        for nested_field in field['nested']:
            count += self._count_leaf_columns(nested_field)
        
        return count
    
    def _generate_html_data_row(self, row_data, header_structure):
        """Generate HTML data rows."""
        cells = self._extract_row_cells(row_data, header_structure)
        max_rows = self._calculate_max_nested_rows(cells)
        
        # Update rowspan for non-nested cells
        for cell in cells:
            if not cell['is_nested']:
                cell['rowspan'] = max_rows
        
        html = ''
        for row_index in range(max_rows):
            html += '<tr>'
            html += self._generate_html_data_cells(cells, row_index, max_rows)
            html += '</tr>\n'
        
        return html
    
    def _extract_row_cells(self, row_data, header_structure):
        """Extract cell data from a data row."""
        cells = []
        
        for field in header_structure:
            key = field['name']
            
            if key in row_data:
                value = row_data[key]
                
                if isinstance(value, list):
                    # Nested data
                    nested_cells_list = []
                    for nested_item in value:
                        nested_cells = self._extract_row_cells(nested_item, field['nested'])
                        nested_cells_list.append(nested_cells)
                    
                    cell_info = {
                        'value': '',
                        'rowspan': len(nested_cells_list),
                        'is_nested': True,
                        'nested_cells': nested_cells_list,
                        'leaf_count': self._count_leaf_columns(field)
                    }
                else:
                    # Simple data
                    cell_info = {
                        'value': str(value),
                        'rowspan': 1,
                        'is_nested': False,
                        'leaf_count': 1
                    }
            else:
                # Missing field
                cell_info = {
                    'value': '',
                    'rowspan': 1,
                    'is_nested': False,
                    'leaf_count': self._count_leaf_columns(field)
                }
            
            cells.append(cell_info)
        
        return cells
    
    def _calculate_max_nested_rows(self, cells):
        """Calculate how many table rows are needed."""
        max_rows = 1
        
        for cell in cells:
            if cell['is_nested']:
                total_rows = 0
                for nested_cells in cell['nested_cells']:
                    nested_max_rows = self._calculate_max_nested_rows(nested_cells)
                    total_rows += nested_max_rows
                
                if total_rows > max_rows:
                    max_rows = total_rows
        
        return max_rows
    
    def _generate_html_data_cells(self, cells, row_index, max_rows):
        """Generate HTML data cells for a specific row."""
        html = ''
        
        for cell in cells:
            if cell['is_nested']:
                nested_cells_list = cell['nested_cells']
                accumulated_rows = 0
                found = False
                
                for nested_cells in nested_cells_list:
                    nested_max_rows = self._calculate_max_nested_rows(nested_cells)
                    
                    if row_index < accumulated_rows + nested_max_rows and not found:
                        relative_row_index = row_index - accumulated_rows
                        html += self._generate_html_data_cells(nested_cells, relative_row_index, nested_max_rows)
                        found = True
                    
                    accumulated_rows += nested_max_rows
                
                if not found:
                    for _ in range(cell['leaf_count']):
                        html += '<td class="td"></td>'
            else:
                if row_index == 0:
                    html += f'<td rowspan="{max_rows}" class="td">{cell["value"]}</td>'
        
        return html
    
    def _generate_text_table(self, header_structure, max_depth, table_list):
        """Generate text-based ASCII table."""
        col_info = self._build_column_info(header_structure, table_list)
        top_border = self._generate_top_border(col_info)
        header_rows = self._generate_header_rows(header_structure, max_depth, col_info)
        header_sep = self._generate_header_separator(col_info)
        body_rows = self._generate_body_rows(table_list, header_structure, col_info)
        bottom_border = top_border
        
        return '\n'.join([top_border, header_rows, header_sep, body_rows, bottom_border])
    
    def _build_column_info(self, structure, table_list):
        """Calculate column widths by scanning headers and data."""
        col_info = self._extract_leaf_columns(structure)
        
        for row_data in table_list:
            cells = self._extract_row_cells(row_data, structure)
            self._update_column_widths(col_info, cells, 0)
        
        return col_info
    
    def _extract_leaf_columns(self, structure):
        """Extract leaf columns from structure."""
        col_info = []
        
        for field in structure:
            if field['nested'] is None:
                col_info.append({'name': field['name'], 'width': len(field['name']) + 2})
            else:
                col_info.extend(self._extract_leaf_columns(field['nested']))
        
        return col_info
    
    def _update_column_widths(self, col_info, cells, col_offset):
        """Recursively update column widths based on data values."""
        current_col = col_offset
        
        for cell in cells:
            if cell['is_nested']:
                for nested_cells in cell['nested_cells']:
                    self._update_column_widths(col_info, nested_cells, current_col)
            else:
                value_len = len(str(cell['value'])) + 2
                if value_len > col_info[current_col]['width']:
                    col_info[current_col]['width'] = value_len
            
            current_col += cell['leaf_count']
    
    def _generate_top_border(self, col_info):
        """Generate top border line."""
        parts = ['-' * col['width'] for col in col_info]
        return '+' + '+'.join(parts) + '+'
    
    def _generate_header_separator(self, col_info):
        """Generate header separator line."""
        parts = ['=' * col['width'] for col in col_info]
        return '+' + '+'.join(parts) + '+'
    
    def _generate_header_rows(self, header_structure, max_depth, col_info):
        """Generate header rows."""
        grid = self._build_header_grid(header_structure, max_depth, col_info)
        lines = self._render_header_grid(grid, max_depth, col_info)
        return '\n'.join(lines)
    
    def _build_header_grid(self, header_structure, max_depth, col_info):
        """Build 2D grid for header."""
        num_cols = len(col_info)
        grid = [[None] * num_cols for _ in range(max_depth)]
        self._fill_header_grid(grid, header_structure, 0, 0, max_depth, col_info)
        return grid
    
    def _fill_header_grid(self, grid, structure, row_idx, col_idx, max_depth, col_info):
        """Fill header grid with cells."""
        current_col = col_idx
        
        for field in structure:
            colspan = self._count_leaf_columns(field)
            
            if field['nested'] is not None:
                cell = {'text': field['name'], 'rowspan': 1, 'colspan': colspan, 'col_start': current_col, 'start_row': row_idx}
                grid[row_idx][current_col] = cell
                
                for i in range(1, colspan):
                    grid[row_idx][current_col + i] = 'SPAN'
                
                self._fill_header_grid(grid, field['nested'], row_idx + 1, current_col, max_depth, col_info)
            else:
                rowspan = max_depth - row_idx
                cell = {'text': field['name'], 'rowspan': rowspan, 'colspan': colspan, 'col_start': current_col, 'start_row': row_idx}
                grid[row_idx][current_col] = cell
                
                for r in range(row_idx + 1, max_depth):
                    grid[r][current_col] = cell
                
                for i in range(1, colspan):
                    for r in range(row_idx, max_depth):
                        grid[r][current_col + i] = 'SPAN'
            
            current_col += colspan
    
    def _render_header_grid(self, grid, max_depth, col_info):
        """Render header grid as text lines."""
        lines = []
        content_rows = []
        
        for row_idx in range(max_depth):
            has_content = False
            for cell in grid[row_idx]:
                if cell != 'SPAN' and cell is not None and cell.get('start_row') == row_idx:
                    has_content = True
                    break
            if has_content:
                content_rows.append(row_idx)
        
        for i, row_idx in enumerate(content_rows):
            line = self._render_header_grid_row(grid[row_idx], row_idx, col_info)
            lines.append(line)
            
            if i < len(content_rows) - 1:
                next_row_idx = content_rows[i + 1]
                sep = self._generate_row_separator(grid[row_idx], grid[next_row_idx], col_info)
                lines.append(sep)
        
        return lines
    
    def _render_header_grid_row(self, row, row_idx, col_info):
        """Render one header grid row."""
        parts = []
        
        for col_idx, cell in enumerate(row):
            if cell == 'SPAN':
                continue
            elif cell is None:
                parts.append(' ' * col_info[col_idx]['width'])
            else:
                text = cell['text']
                colspan = cell['colspan']
                col_start = cell['col_start']
                start_row = cell['start_row']
                
                total_width = sum(col_info[col_start + i]['width'] + 1 for i in range(colspan)) - 1
                
                display_text = text if row_idx - start_row == 0 else ''
                text_len = len(display_text)
                padding = total_width - text_len
                left_pad = padding // 2
                right_pad = padding - left_pad
                padded_text = ' ' * left_pad + display_text + ' ' * right_pad
                parts.append(padded_text)
        
        return '|' + '|'.join(parts) + '|'
    
    def _generate_row_separator(self, current_row, next_row, col_info):
        """Generate separator line between rows."""
        parts = []
        
        for col_idx in range(len(col_info)):
            curr_cell = current_row[col_idx]
            next_cell = next_row[col_idx]
            width = col_info[col_idx]['width']
            
            is_continuing = (curr_cell != 'SPAN' and next_cell != 'SPAN' and 
                           curr_cell is not None and next_cell is not None and 
                           curr_cell is next_cell)
            
            parts.append(' ' * width if is_continuing else '-' * width)
        
        sep = ''
        for i, part in enumerate(parts):
            if i == 0:
                sep = ('+' if '-' in part else '|') + part
            else:
                prev_part = parts[i - 1]
                has_left_dash = '-' in prev_part
                has_right_dash = '-' in part
                sep += ('+' if has_left_dash or has_right_dash else '|') + part
        
        last_part = parts[-1]
        sep += '+' if '-' in last_part else '|'
        
        return sep
    
    def _generate_body_rows(self, table_list, header_structure, col_info):
        """Generate body rows."""
        all_lines = []
        
        for data_row_idx, row_data in enumerate(table_list):
            cells = self._extract_row_cells(row_data, header_structure)
            num_text_rows = self._calculate_max_nested_rows(cells)
            grid = self._build_body_grid(cells, num_text_rows, col_info)
            row_lines = self._render_body_grid(grid, num_text_rows, col_info)
            all_lines.extend(row_lines)
            
            if data_row_idx < len(table_list) - 1:
                all_lines.append(self._generate_data_row_separator(col_info))
        
        return '\n'.join(all_lines)
    
    def _build_body_grid(self, cells, num_text_rows, col_info):
        """Build 2D grid for body."""
        num_cols = len(col_info)
        grid = [[None] * num_cols for _ in range(num_text_rows)]
        self._fill_body_grid(grid, cells, 0, 0, num_text_rows)
        return grid
    
    def _fill_body_grid(self, grid, cells, row_offset, col_offset, num_text_rows):
        """Fill body grid with cells."""
        current_col = col_offset
        
        for cell in cells:
            if cell['is_nested']:
                current_row = row_offset
                for nested_cells in cell['nested_cells']:
                    nested_rows = self._calculate_max_nested_rows(nested_cells)
                    self._fill_body_grid(grid, nested_cells, current_row, current_col, nested_rows)
                    current_row += nested_rows
            else:
                value = str(cell['value'])
                cell_info = {'value': value, 'rowspan': num_text_rows, 'colspan': cell['leaf_count'], 
                           'col_start': current_col, 'start_row': row_offset}
                
                for r in range(row_offset, row_offset + num_text_rows):
                    grid[r][current_col] = cell_info
                
                for c in range(1, cell['leaf_count']):
                    for r in range(row_offset, row_offset + num_text_rows):
                        grid[r][current_col + c] = 'SPAN'
            
            current_col += cell['leaf_count']
    
    def _render_body_grid(self, grid, num_text_rows, col_info):
        """Render body grid as text lines."""
        lines = []
        
        for row_idx in range(num_text_rows):
            line = self._render_body_grid_row(grid[row_idx], row_idx, col_info)
            lines.append(line)
            
            if row_idx < num_text_rows - 1:
                sep = self._generate_row_separator(grid[row_idx], grid[row_idx + 1], col_info)
                lines.append(sep)
        
        return lines
    
    def _render_body_grid_row(self, row, row_idx, col_info):
        """Render one body grid row."""
        parts = []
        
        for col_idx, cell in enumerate(row):
            if cell == 'SPAN':
                continue
            elif cell is None:
                parts.append(' ' * col_info[col_idx]['width'])
            else:
                value = cell['value']
                colspan = cell['colspan']
                col_start = cell['col_start']
                start_row = cell['start_row']
                
                total_width = sum(col_info[col_start + i]['width'] + 1 for i in range(colspan)) - 1
                
                display_text = value if row_idx - start_row == 0 else ''
                text_len = len(display_text)
                padding = total_width - text_len
                left_pad = padding // 2
                right_pad = padding - left_pad
                padded_text = ' ' * left_pad + display_text + ' ' * right_pad
                parts.append(padded_text)
        
        return '|' + '|'.join(parts) + '|'
    
    def _generate_data_row_separator(self, col_info):
        """Generate separator between data rows."""
        parts = ['-' * col['width'] for col in col_info]
        return '+' + '+'.join(parts) + '+'

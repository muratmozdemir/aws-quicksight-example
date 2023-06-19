import os
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

data_path = 'resources/data'

# Create the students parquet file.
students_data = {
    'id': [1, 2, 3, 4, 5],
    'name': ['Alice', 'Bob', 'Charlie', 'Dave', 'Eve'],
    'favorite_color': ['blue', 'green', 'red', 'yellow', 'purple'],
    'favorite_programming_language': ['Python', 'Java', 'C++', 'JavaScript', 'Ruby'],
    'country' : ['Germany', 'United States', 'Canada', 'United States', 'Mexico']
}

students_df = pd.DataFrame(students_data)

# Converting the DataFrame to an Arrow Table
students_table = pa.Table.from_pandas(students_df)

# Writing the Table to a Parquet File
pq.write_table(students_table, os.path.join(data_path, 'students.parquet'))


# Create the enrollments parquet file
enrollments_data = {
    'student_id': [1, 2, 3, 4, 5],
    'enrolled_class': ['Geometry', 'Algebra', 'Art', 'Earth Science', 'English'],
}

enrollments_df = pd.DataFrame(enrollments_data)

# Converting the DataFrame to an Arrow Table
enrollments_table = pa.Table.from_pandas(enrollments_df)

# Writing the Table to a Parquet File
pq.write_table(enrollments_table, os.path.join(data_path, 'enrollments.parquet'))
